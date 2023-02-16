// This shader fills the mesh shape with a color predefined in the code.
Shader "TAHair"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseColorMap("Base (RGB)", 2D) = "white" {}
        [Normal]_NormalMap("Normal (RGB)", 2D) = "bump" {}
        //        _MetallicMap("Metallic (R)", 2D) = "white" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.5
        _ShiftTex("shiftTex", 2D) = "white" {}
        _Shift1("Shift1", Range(0,1)) = 0.5
        _Shift2("Shift2", Range(0,1)) = 0.5
        _SpecularColor1("specularColor1", Color) = (1,1,1,1)
        _SpecularExponent1("specularExponent1", Range(0,1000)) = 1
        _SpecularColor2("specularColor2", Color) = (1,1,1,1)
        _SpecularExponent2("specularExponent2", Range(0,1000)) = 1
        //        _Metallic("Metallic", Range(0,1)) = 0.5
        [Normal]_MacoNormalMap("MacoNormal (RGB)", 2D) = "bump" {}
        _MacoNormalWeight("MacoNormalWeight", Range(0,1)) = 0.5
        _BRDF("BRDF", 2d) = "white" {}
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags
        {
            "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"
        }
        ZWrite On
        ZTest LEqual
        Cull Off

        Pass
        {
            Tags
            {
                "LightMode" = "DepthPeelingPass"
            }
            //            Cull OFF
            //            ZWrite On
            //            Blend SrcAlpha OneMinusSrcAlpha

            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ColorMask RGBA

            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Assets/101/Skin/HLSL/TAHair.hlsl"
            float4 _BaseColor;
            sampler2D _BRDF;
            sampler2D _BaseColorMap;
            sampler2D _NormalMap;
            // sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            // sampler2D _ShiftTex;
            // float _Shift1;
            // float _Shift2;
            // float4 _SpecularColor1;
            // float _SpecularExponent1;
            // float4 _SpecularColor2;
            // float _SpecularExponent2;


            // float _Metallic;
            sampler2D _MacoNormalMap;
            float4 _MacoNormalMap_ST;
            float _MacoNormalWeight;
            int _DepthPeelingPassCount; //当前第几层
            sampler2D _MaxDepth;
            //Physically based Shading
            //Cook-Torrance BRDF

            /////////////////DFG/////////////////////

            //D
            float D_DistributionGGX(float3 N, float3 H, float Roughness)
            {
                // outBRDFData.roughness           = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
                //  outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);

                float a = max(Roughness * Roughness,HALF_MIN_SQRT);
                float a2 = max(a * a,HALF_MIN);
                float NH = saturate(dot(N, H));
                float NH2 = NH * NH;
                float nominator = a2;
                float denominator = (NH2 * (a2 - 1.0) + 1.0);
                denominator = PI * denominator * denominator;
                return nominator / max(denominator, 0.001); //防止分母为0
            }

            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                float a = roughness * roughness;
                float a2 = a * a;
                float NdotH = max(dot(N, H), 0.0);
                float NdotH2 = NdotH * NdotH;

                float nom = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;

                return nom / denom;
            }

            //Trowbridge-Reitz GGX
            float D_GGX(float3 N, float3 H, float Roughness)
            {
                float a = max(0.001, Roughness * Roughness);
                float a2 = a * a;
                float NdotH = saturate(dot(N, H));
                float NdotH2 = NdotH * NdotH;
                float nom = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;
                return nom / denom;
            }

            //Schlick Fresnel
            float3 F_Schlickss(float3 F0, float3 N, float3 V)
            {
                float VdotH = saturate(dot(V, N));
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            //////////////////////////////////////////////////benckman///////////////////////////////////////////
            float PHBeckmann(float ndoth, float m)
            {
                float alpha = acos(ndoth);
                float ta = tan(alpha);
                float val = 1.0 / (m * m * pow(ndoth, 4.0)) * exp(-(ta * ta) / (m * m));
                return val;
            } // Render a screen-aligned quad to precompute a 512x512 texture.
            float KSTextureCompute(float2 tex : TEXCOORD0)
            {
                // Scale the value to fit within [0,1] – invert upon lookup.
                return 0.5 * pow(PHBeckmann(tex.x, tex.y), 0.1);
            }


            //Schlick Fresnel
            float3 fresnelReflectance(float3 N, float3 V, float3 F0)
            {
                float VdotH = saturate(dot(V, N));
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float KS_Skin_Specular(
                float3 N, // Bumped surface normal
                float3 L, // Points to light
                float3 V, // Points to eye
                float m, // Roughness
                float rho_s, // Specular brightness
                float F
                //sampler2D beckmannTex
            )
            {
                float result = 0.0;
                float ndotl = dot(N, L);
                if (ndotl > 0.0)
                {
                    float3 h = L + V; // Unnormalized half-way vector
                    float3 H = normalize(h);

                    float ndoth = saturate(dot(N, H));
                    // float PH = pow(2.0 * tex2D(beckmannTex, float2(ndoth, m)), 10.0);
                    float PH = pow(2.0 * KSTextureCompute(float2(ndoth, m)), 10.0);
                    // float F = fresnelReflectance(N, V, 0.028);
                    float frSpec = max(PH * F / dot(h, h), 0);
                    result = ndotl * rho_s * frSpec; // BRDF * dot(N,L) * rho_s
                }
                return result;
            }

            //////////////////////////////////////////////////benckman end///////////////////////////////////////////

            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                float r = 1.0 - roughness;
                return F0 + (max(r.xxx, F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }


            //UE4 Black Ops II modify version
            float2 EnvBRDFApprox(float Roughness, float NV)
            {
                // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
                // Adaptation to fit our G term.
                const float4 c0 = {-1, -0.0275, -0.572, 0.022};
                const float4 c1 = {1, 0.0425, 1.04, -0.04};
                float4 r = Roughness * c0 + c1;
                float a004 = min(r.x * r.x, exp2(-9.28 * NV)) * r.x + r.y;
                float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
                return AB;
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r * r) / 8.0;

                float nom = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }

            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx1 = GeometrySchlickGGX(NdotV, roughness);
                float ggx2 = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }


            /////////////////
            float GeometrySchlickGGXInderect(float NdotV, float roughness)
            {
                float a = roughness;
                float k = (a * a) / 2.0;

                float nom = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }

            // ----------------------------------------------------------------------------
            float GeometrySmithInderect(float N, float V, float L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2 = GeometrySchlickGGXInderect(NdotV, roughness);
                float ggx1 = GeometrySchlickGGXInderect(NdotL, roughness);

                return ggx1 * ggx2;
            }


            float3 PreIntegratedSkinWithCurveApprox(half NdotL, half curvature)
            {
                // NdotL = mad(NdotL, 0.5, 0.5); // map to 0 to 1 range
                float curva = (1.0 / mad(curvature, 0.5 - 0.0625, 0.0625) - 2.0) / (16.0 - 2.0);
                // curvature is within [0, 1] remap to normalized r from 2 to 16
                float oneMinusCurva = 1.0 - curva;
                float3 curve0;
                {
                    float3 rangeMin = float3(0.0, 0.3, 0.3);
                    float3 rangeMax = float3(1.0, 0.7, 0.7);
                    float3 offset = float3(0.0, 0.06, 0.06);
                    float3 t = saturate(mad(NdotL, 1.0 / (rangeMax - rangeMin),
                                            (offset + rangeMin) / (rangeMin - rangeMax)));
                    float3 lowerLine = (t * t) * float3(0.65, 0.5, 0.9);
                    lowerLine.r += 0.045;
                    lowerLine.b *= t.b;
                    float3 m = float3(1.75, 2.0, 1.97);
                    float3 upperLine = mad(NdotL, m, float3(0.99, 0.99, 0.99) - m);
                    upperLine = saturate(upperLine);
                    float3 lerpMin = float3(0.0, 0.35, 0.35);
                    float3 lerpMax = float3(1.0, 0.7, 0.6);
                    float3 lerpT = saturate(mad(NdotL, 1.0 / (lerpMax - lerpMin), lerpMin / (lerpMin - lerpMax)));
                    curve0 = lerp(lowerLine, upperLine, lerpT * lerpT);
                }
                float3 curve1;
                {
                    float3 m = float3(1.95, 2.0, 2.0);
                    float3 upperLine = mad(NdotL, m, float3(0.99, 0.99, 1.0) - m);
                    curve1 = saturate(upperLine);
                }
                float oneMinusCurva2 = oneMinusCurva * oneMinusCurva;
                float3 brdf = lerp(curve0, curve1, mad(oneMinusCurva2, -1.0 * oneMinusCurva2, 1.0));
                return brdf;
            }


            /////////////////END DFG/////////////////////
            // This line defines the name of the vertex shader.
            #pragma vertex vert
            // This line defines the name of the fragment shader.
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The structure definition defines which variables it contains.
            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                float3 tangentOS : TANGENT;
                // float3 tangent : TANGENT;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float4 screenPos : TEXCOORD5;
                // float3 bitangentWS : TEXCOORD4;
            };


            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS = positionWS;
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS);
                OUT.uv = IN.uv;
                OUT.screenPos = ComputeScreenPos(OUT.positionHCS);
                return OUT;
            }

            struct DepthPeelingOutput
            {
                float4 color:SV_TARGET0;
                float4 depth:SV_TARGET1;
            };


            // The fragment shader definition.
            DepthPeelingOutput frag(Varyings data, bool isFont : SV_IsFrontFace) : SV_Target
            {
                DepthPeelingOutput output;
                Light light = GetMainLight();
                float3 meshNormal = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(meshNormal, T);
                float3x3 TBN = float3x3(T, B, meshNormal);

                float3 normalTS = SafeNormalize(UnpackNormal(tex2D(_NormalMap, data.uv)));
                float3 detailNormalTS = SafeNormalize(
                    UnpackNormal(tex2D(_MacoNormalMap, data.uv * _MacoNormalMap_ST.xy + _MacoNormalMap_ST.zw)));
                float3 MacoNormal = SafeNormalize(detailNormalTS);
                normalTS = lerp(normalTS, BlendNormalRNM(normalTS, MacoNormal), _MacoNormalWeight);
                normalTS = SafeNormalize(normalTS);
                float3 N = mul(normalTS, TBN);
                float3 V = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float nv = saturate(dot(N, V));


                float4 albedo = tex2D(_BaseColorMap, data.uv) * _BaseColor;


                float3 finalColor = HairLighting(T, N, V, data.uv, albedo, light);
                half Roughness = max(tex2D(_RoughnessMap, data.uv) * _Roughness, 0.000001);
                half3 F0 = half3(0.04, 0.04, 0.04);
                half3 inKs = fresnelSchlickRoughness(nv, F0, Roughness);
                half3 inKD = 1 - inKs;
                half3 inDiffuse = SampleSH(N) * albedo * inKD; ///PI;
                output.color = float4(finalColor.xyz + inDiffuse, albedo.a);
                output.depth = data.positionHCS.z;
                if (_DepthPeelingPassCount == 0) //第一次直接渲染
                {
                    return output;
                }
                // return float4(finalColor.xyz + inDiffuse, albedo.a);

                float2 screenUV = data.screenPos.xy / data.screenPos.w;

                float lastDepth = tex2D(_MaxDepth, screenUV).r;
                float pixelDepth = data.positionHCS.z;
                if (pixelDepth <= lastDepth)
                {
                    discard;
                }
                return output;
            }
            ENDHLSL
        }
    }
}