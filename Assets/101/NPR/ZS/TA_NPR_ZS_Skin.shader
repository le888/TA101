// This shader fills the mesh shape with a color predefined in the code.
Shader "TA_NPR_ZS_Skin"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture]_BaseMap("Base (RGB)", 2D) = "white" {}
        _StepValue("StepValue", Range(-1,1)) = 0.5
        _Step2Value("Step2Value", Range(-1,1)) = 0.5
        _DralkColor("DralkColor", Color) = (0.7,0.7,0.7,1)
        _BrightColor("BrightColor", Color) = (1,1,1,1)
//        _DralkIntensity("DralkColorIntensity", Range(0,1)) = 0.7
//        _brightIntensity("brightColorIntensity", Range(0,1)) = 1
        [Toggle]_UseBright2("UseBright2",float) = 0
        _Bright2Intensity("Bright2Intensity", Range(0,1)) = 0
        [Normal]_BumpMap("Normal (RGB)", 2D) = "bump" {}
        [Toggle]_AODichotomy("AODichotomy",float) = 1
        _AOMap("Ao (R)", 2D) = "white" {}
        //        _MetallicMap("Metallic (R)", 2D) = "white" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.5
        [Toggle]_UseGGX("UseGGX",float) = 0
        _PBRComm("PBRComm", 2D) = "black" {}
        _OutLineSize("outLineSize", Range(0,1)) = 0.1
        _OutLineColor("outLineColor", Color) = (0,0,0,1)
        [Toggle]_UseRamp("UseRamp",float) = 0
        _RampMap("RampMap", 2D) = "black" {}
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
            name "TA_NPR_ZS_Skin Ex"
            ZWrite Off
            ZTest LEqual
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Assets/HLSL/PBRComm.hlsl"
            #include "Assets/HLSL/SkinComm.hlsl"
            float4 _BaseColor;
            sampler2D _BRDF;
            sampler2D _BaseMap;
            float _StepValue;
            float4 _DralkColor;
            float4 _BrightColor;
            sampler2D _BumpMap;
            sampler2D _AOMap;
            // sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            float _UseGGX;
            sampler2D _PBRComm;
            float _OutLineSize;
            float4 _OutLineColor;

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
                float3 Color:COLOR;
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
                float3 Color:COLOR;
                // float3 bitangentWS : TEXCOORD4;
            };


            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                float3 position = IN.positionOS.xyz+IN.normalOS*0.0001*_OutLineSize* IN.Color.b;
                OUT.positionHCS = TransformObjectToHClip(position);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                float3 positionWS = TransformObjectToWorld(position);
                OUT.positionWS = positionWS;
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS);
                OUT.uv = IN.uv;
                OUT.Color = IN.Color;
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings data) : SV_Target
            {
                Light light = GetMainLight();
                float3 L = SafeNormalize(light.direction);
                float3 meshNormal = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(meshNormal, T);
                float3x3 TBN = float3x3(T, B, meshNormal);

                float3 normalTS = SafeNormalize(UnpackNormal(tex2D(_BumpMap, data.uv)));

                float3 N = mul(normalTS, TBN);
                // return  N.xyzz;
                float3 V = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float3 H = SafeNormalize(L + V);
                float nl = dot(N, L);
                float nv = dot(N, V);
               
                return _OutLineColor;
            }
            ENDHLSL
        }
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            ZWrite On
            ZTest LEqual
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Assets/HLSL/PBRComm.hlsl"
            #include "Assets/HLSL/SkinComm.hlsl"
            float4 _BaseColor;
            sampler2D _BRDF;
            sampler2D _BaseMap;
            float _StepValue;
            float _Step2Value;
            float4 _DralkColor;
            float4 _BrightColor;
            sampler2D _BumpMap;
            float _AODichotomy;
            sampler2D _AOMap;
            // sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            float _UseGGX;
            sampler2D _PBRComm;
            float _UseRamp;
            sampler2D _RampMap;
            float _BrightIntensity;
            float _DrakIntensity;
            float _Bright2Intensity;
            float _UseBright2;
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
                float3 Color:COLOR;
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
                float3 Color:COLOR;
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
                OUT.Color = IN.Color;
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings data) : SV_Target
            {
                Light light = GetMainLight();
                float3 L = SafeNormalize(light.direction);
                float3 meshNormal = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(meshNormal, T);
                float3x3 TBN = float3x3(T, B, meshNormal);

                float3 normalTS = SafeNormalize(UnpackNormal(tex2D(_BumpMap, data.uv)));

                float3 N = mul(normalTS, TBN);
                // return  N.xyzz;
                float3 V = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float3 H = SafeNormalize(L + V);
                float nl = dot(N, L);
                float nl01 = nl * 0.5 + 0.5;
                float nv = dot(N, V);
                 float4 AOColor = tex2D(_AOMap, data.uv);
                // return AOColor.b;
                float lightAtt = light.distanceAttenuation * light.shadowAttenuation * light.color;
                float4 albedo = tex2D(_BaseMap, data.uv);

                if (_UseRamp == 1)
                {
                    float3 rampColor = tex2D(_RampMap, half2(nl01, 0.5));
                    albedo.rgb *= rampColor;
                }
                
                float4 finalColor = albedo * _BaseColor;
                float nlStepValue = step(_StepValue , nl); //二分光源区域
                 float nlStep2Value = step(_Step2Value , nl); //二分光源区域

                float ShadowAO = AOColor.g;
                if (_AODichotomy == 1)
                {
                        ShadowAO = AOColor.g>0.1;
                }
                
                // float ShadowAO = 1;
                // return N.xyzz;
                finalColor = lerp(finalColor * _DralkColor, finalColor * _BrightColor, nlStepValue * ShadowAO);
                if (_UseBright2 == 1)
                {
                    finalColor = lerp(finalColor * _Bright2Intensity,finalColor, nlStep2Value * ShadowAO);
                }
                 
                
                // return finalColor;
                finalColor *= lightAtt;


                // return AOColor.a;
                
                //高光
                if (_UseGGX == 1)
                {
                    float4 pbrData = tex2D(_PBRComm, data.uv); //R:金属度  G:粗糙度 B:高光遮罩 alpha:控制高光类型
                    
                    //ggx 高光
                    half3 F0 = half3(0.04, 0.04, 0.04);
                    half _Metallic = pbrData.r;
                    half _RoughnessValue = pbrData.g * _Roughness;
                    F0 = lerp(F0, albedo, _Metallic);
                    float D = D_GGX(N, H, _RoughnessValue) * (pbrData.a > 0.3);
                    float G = GeometrySmith(N, V, L, _RoughnessValue);
                    float3 F = F_Schlickss(F0, N, V);
                    float3 nominator   = D * G * F;
                    // float denominator = 4.0 * (nl * nv);
                    float denominator = (nl * nv);
                    float3 specular = nominator / max(denominator, 0.001);
                    // return D.xxxx;
                    // return pbrData.xxxx;
                    // return pbrData.yyyy;
                    // return pbrData.zzzz;
                    // return pbrData.wwww;
                    float ggx = specular * nlStepValue;
                    finalColor += ggx;
                }
                else
                {
                    
                     //ggx 高光
                    // half3 F0 = half3(0.04, 0.04, 0.04);
                    // half _Metallic = albedo.b;
                    // half _RoughnessValue = albedo.r * _Roughness;
                    // F0 = lerp(F0, albedo, _Metallic);
                    // float D = D_GGX(N, H, _RoughnessValue);
                    // float G = GeometrySmith(N, V, L, _RoughnessValue);
                    // float3 F = F_Schlickss(F0, N, V);
                    // float3 nominator   = D * G * F;
                    // // float denominator = 4.0 * (nl * nv);
                    // float denominator = (nl * nv);
                    // float3 specular = nominator / max(denominator, 0.001);
                    // // return D.xxxx;
                    // // return pbrData.xxxx;
                    // // return pbrData.yyyy;
                    // // return pbrData.zzzz;
                    // // return pbrData.wwww;
                    // float ggx = specular * nlStepValue;
                    // finalColor += ggx;
                    // finalColor += AOColor.b;
                }


                // return nlStepValue.xxxx;
                // return data.Color.xxxx;
                // return data.Color.yyyy;
                // return data.Color.zzzz;
                half3 inKs =  half3(0.04, 0.04, 0.04);
                half3 inKD = 1 - inKs;
                
                half3 inDiffuse = SampleSH(N) * albedo * inKD;///PI;
                finalColor.rgb+=inDiffuse;
                return finalColor;
            }
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}