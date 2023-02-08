// This shader fills the mesh shape with a color predefined in the code.
Shader "SWIMPBR_Aniso"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseColorMap("Base (RGB)", 2D) = "white" {}
        [Normal]_NormalMap("Normal (RGB)", 2D) = "bump" {}
        _MetallicMap("Metallic (R)", 2D) = "white" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.5
        _Roughness2("Roughness2", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.5
        _Aisotropic("Aisotropic", Range(0,1)) = 0.5
        _Aisotropic2("Aisotropic", Range(0,1)) = 0.5
        _AisotropicColor("AisotropicColor", Color) = (1,1,1,1)
        _AisotropicColor2("AisotropicColor2", Color) = (1,1,1,1)
        _BRDF("BRDF", 2d) = "white" {}
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
            sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            float _Roughness2;
            float _Metallic;
            float _Aisotropic;
            float _Aisotropic2;
            float4 _AisotropicColor;
            float4 _AisotropicColor2;
            //Physically based Shading
            //Cook-Torrance BRDF
            
             /////////////////DFG/////////////////////

             //D
            float D_DistributionGGX(float3 N,float3 H,float Roughness)
            {
                // outBRDFData.roughness           = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN_SQRT);
                //  outBRDFData.roughness2          = max(outBRDFData.roughness * outBRDFData.roughness, HALF_MIN);
                
                float a             = max(Roughness*Roughness,HALF_MIN_SQRT) ;
                float a2            = max(a*a,HALF_MIN) ;
                float NH            = saturate(dot(N,H));
                float NH2           = NH*NH;
                float nominator     = a2;
                float denominator   = (NH2*(a2-1.0)+1.0);
                denominator         = PI * denominator*denominator;
                return              nominator/ max(denominator,0.001) ;//防止分母为0
            }

            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                float a      = roughness*roughness;
                float a2     = a*a;
                float NdotH  = max(dot(N, H), 0.0);
                float NdotH2 = NdotH*NdotH;

                float nom   = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;

                return nom / denom;
            }
            
            //Trowbridge-Reitz GGX
            float D_GGX(float3 N,float3 H,float Roughness)
            {
                float a = max(0.001,Roughness * Roughness);
                float a2 = a * a;
                float NdotH = saturate(dot(N, H));
                float NdotH2 = NdotH * NdotH;
                float nom = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = PI * denom * denom;
                return nom / denom;
            }

            float D_GGXaniso( float ax, float ay, float NoH, float3 H, float3 X, float3 Y )
            {
	            float XoH = dot( X, H );
	            float YoH = dot( Y, H );
	            float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
	            return 1 / ( PI * ax*ay * d*d );
            }
            
            //Schlick Fresnel
            float3 F_Schlickss(float3 F0, float3 N, float3 V)
            {
                float VdotH = saturate(dot(V, N));
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
                float r = 1.0 - roughness;
                return F0 + (max(r.xxx, F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }
            

            //UE4 Black Ops II modify version
            float2 EnvBRDFApprox(float Roughness, float NV )
            {
                // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
                // Adaptation to fit our G term.
                const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
                const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
                float4 r = Roughness * c0 + c1;
                float a004 = min( r.x * r.x, exp2( -9.28 * NV ) ) * r.x + r.y;
                float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
                return AB;
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NdotV;
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

                float nom   = NdotV;
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
                float3 N = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(N, T);
                float3x3 TBN = float3x3(T, B, N);
                
                float3 n = SafeNormalize(UnpackNormal(tex2D(_NormalMap,data.uv)));
                n = mul(n,TBN);
                // return  n.xyzz;
                float3 v = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float3 h = SafeNormalize(l + v);
                float nv = saturate(dot(n, v));
                float nl = saturate(dot(n, l));
                // /////直接光照////////////////
                // ////diffuse
                //
                float3 albedo = tex2D(_BaseColorMap,data.uv) * _BaseColor.rgb;
                
                 
                half3 F0 = half3(0.04, 0.04, 0.04);
                _Metallic = tex2D(_MetallicMap,data.uv) * _Metallic;
                F0 = lerp(F0, albedo, _Metallic);

                half Roughness = tex2D(_RoughnessMap,data.uv) * _Roughness;
                half Roughness2 = tex2D(_RoughnessMap,data.uv) * _Roughness2;

                //smithG_GGX_aniso
                // specular
                float aspect = sqrt(1-_Aisotropic*.9);
                float aspect2 = sqrt(1-_Aisotropic2*.9);
                float ax = max(.001, sqrt(Roughness)/aspect);
                float ay = max(.001, sqrt(Roughness)*aspect);

                float ax2 = max(.001, sqrt(Roughness2)/aspect2);
                float ay2 = max(.001, sqrt(Roughness2)*aspect2);
                float Gs, Gs2;
                float3 X = T;
                float3 Y = B;
                Gs  = D_GGXaniso(ax, ay, dot(n,h),h, X, Y);
                // Gs *= Gs;
                Gs2 = D_GGXaniso(ax2, ay2, dot(n,h),h, X, Y);
                Gs = max(Gs, Gs2);
                // return Gs.xxxx;
                //cook-torrance brdf
                float D = Gs;// + D_GGX(n,h,Roughness);
                float G = GeometrySmith(n, v, l, Roughness);
                float3 F = F_Schlickss(F0,n,v);
                // return F.xyzz;
                float3 kS = F;
                float3 kD = 1.0 - kS;
                kD *= 1.0 - _Metallic;
                float3 nominator   = D * G * F;
                float denominator = 4.0 * (nl * nv);
                float3 specular = nominator / max(denominator, 0.001);
                specular *= _AisotropicColor;

                float radiance = light.color* light.distanceAttenuation* light.shadowAttenuation;
                float3 difuse = albedo / PI ;
                 // float3 difuse = albedo;
                float4 directColor = float4((kD * difuse + specular) * nl * radiance, 1.0);
                // return directColor;

                //间接光照,SampleSH 球谐函数/////////////////////////////////////////////////////////////////////////////
                half3 inKs = fresnelSchlickRoughness(nv, F0, Roughness);
                half3 inKD = 1 - inKs;
                inKD *= 1 - _Metallic;
                half3 inDiffuse = SampleSH(n) * albedo * inKD;///PI;
                // return  inDiffuse.xyzz;
                //间接高光，split sum approximation   一部分和diffuse一样加了对环境贴图卷积，不过这次用粗糙度区分了mipmap
                 half mip = PerceptualRoughnessToMipmapLevel(Roughness);
                 half3 reflectVector = reflect(-v, n);
                 half4 encodedIrradiance = half4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));
                 real3 inspecPart1 = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                 // float2 brdf = tex2D(_BRDF, float2(nv, Roughness)).rg;
                float2 brdf = EnvBRDFApprox(Roughness, nv);
                 half3 inspectPart2 = (inKs * brdf.x + brdf.y);
                 half3 inspect =inspecPart1 * inspectPart2;
                float3 ambient = (inDiffuse + inspect);
                float3 finalColor = ambient + directColor.xyz;
                return (finalColor).xyzz;; 
                    
            }
            ENDHLSL
        }
    }
}