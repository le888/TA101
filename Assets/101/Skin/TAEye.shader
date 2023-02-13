   // This shader fills the mesh shape with a color predefined in the code.
Shader "TA/Eye"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseColorMap("Base (RGB)", 2D) = "white" {}
        [Normal]_NormalMap("Normal (RGB)", 2D) = "bump" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 1
        _Mask("Mask", 2D) = "black" {}
        _CubeMap("CubeMap", Cube) = "white" {}
        _ReflectionCubeRot("_ReflectionCubeRot",float) = 0
        _ReflectionFactor("_ReflectionFactor",vector) = (1,1,1,1)

        [Toggle]_OnlySpecular("OnlySpecular", Float) = 0
        [Toggle]_DisableSpecular("DisableDiffuse", Float) = 0

        [Space(15)]
        [Header(Blend Mode)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode("Src Blend Mode", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode("Dst Blend Mode", Float) = 0
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
            Blend[_SrcBlendMode][_DstBlendMode]
            ZWrite On
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

            float4 _BaseColor;
            sampler2D _BRDF;
            sampler2D _BaseColorMap;
            sampler2D _NormalMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            sampler2D _Mask;
            samplerCUBE _CubeMap;
            float _ReflectionCubeRot;
            float4 _ReflectionFactor;
            float _OnlySpecular;
            float _DisableSpecular;


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


            /////////////////////////////

            float3 Erot(float3 p, float3 ax, float angle)
            {
                return lerp(dot(ax, p) * ax, p, cos(angle)) + cross(ax, p) * sin(angle);
            }

            ///
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
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings data) : SV_Target
            {
                Light light = GetMainLight();
                float3 l = SafeNormalize(light.direction);
                float3 meshNormal = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(meshNormal, T);
                float3x3 TBN = float3x3(T, B, meshNormal);

                float3 normalTS = SafeNormalize(UnpackNormal(tex2D(_NormalMap, data.uv)));

                float3 N = mul(normalTS, TBN);
                // return  N.xyzz;
                float3 v = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float3 h = SafeNormalize(l + v);
                float nv = saturate(dot(N, v));
                float nlNotClamped = dot(meshNormal, l);
                float nl01 = mad(nlNotClamped, 0.5, 0.5);
                float nl = saturate(nlNotClamped);
                // /////直接光照////////////////
                // ////diffuse
                //
                float3 albedo = tex2D(_BaseColorMap, data.uv) * _BaseColor.rgb;
                float mask = tex2D(_Mask, data.uv);

                // return finalColor.xyzz;
                // return float4(specular.xxx,1);
                half3 F0 = half3(0.04, 0.04, 0.04);
                float _Metallic = 0;
                F0 = F0; //lerp(F0, albedo, _Metallic);

                half Roughness = tex2D(_RoughnessMap, data.uv) * _Roughness;
                //cook-torrance brdf
                float D = D_GGX(N, h, Roughness);
                float G = GeometrySmith(N, v, l, Roughness);
                float3 F = F_Schlickss(F0, N, v);
                // return F.xyzz;
                float3 kS = F;
                float3 kD = 1.0 - kS;
                kD *= 1.0 - _Metallic;
                float3 nominator = D * G * F;
                float denominator = 4.0 * (nl * nv);
                float3 specular = nominator / max(denominator, 0.001);
                //
                //
                float radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                float3 difuse = albedo / PI;
                //float3 difuse = albedo;
                float4 directColor = float4((kD * difuse + specular) * nl * radiance, 1.0);


                //
                // //间接光照,SampleSH 球谐函数/////////////////////////////////////////////////////////////////////////////
                half3 inKs = fresnelSchlickRoughness(nv, F0, Roughness);
                half3 inKD = 1 - inKs;
                inKD *= 1 - _Metallic;
                half3 inDiffuse = SampleSH(N) * albedo * inKD; ///PI;
                // return  inDiffuse.xyzz;
                //间接高光，split sum approximation   一部分和diffuse一样加了对环境贴图卷积，不过这次用粗糙度区分了mipmap
                half mip = PerceptualRoughnessToMipmapLevel(Roughness);
                half3 reflectVector = reflect(-v, N);
                half4 encodedIrradiance = half4(
                    SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));
                real3 inspecPart1 = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                // float2 brdf = tex2D(_BRDF, float2(nv, Roughness)).rg;
                float2 brdf = EnvBRDFApprox(Roughness, nv);
                half3 inspectPart2 = (inKs * brdf.x + brdf.y);
                half3 inspect = inspecPart1 * inspectPart2;
                float3 ambient = (inDiffuse + inspect);
                // float3 finalColor = ambient + directColor.xyz;
                // return (finalColor).xyzz;; 

                

                float4 finalColor = float4(0, 0, 0, 1);
                UNITY_BRANCH if (_OnlySpecular == 1)
                {
                     float3 R = reflect(-v, N);

                    //获取 CubeMap
                    R = Erot(R, float3(0, 1, 0), _ReflectionCubeRot);
                    float4 cubeColor = texCUBE(_CubeMap, R);
                    cubeColor = pow(cubeColor,_ReflectionFactor.x)* _ReflectionFactor.y*mask.r;
                    // return mask.rrrr;
                    // finalColor.rgb = cubeColor;
                    finalColor.rgb = (specular + cubeColor)* nl * radiance;
                }
                else
                {
                    // return cubeColor;
                    finalColor.rgb = float3(1,1,1);
                    finalColor.rgb = float4((kD * difuse) * nl * radiance, 1.0) + ambient;
                }


                return finalColor.xyzz;
            }
            ENDHLSL
        }
    }
}