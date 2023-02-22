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
        _AlphaClip("AlphaClip", Range(0,1)) = 0.014
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

        Pass
        {
            Tags
            {
                "LightMode" = "DepthPeelingPass"
            }
         
            ZWrite On
            ZTest LEqual
            Cull Off
            Blend Off
//            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
//            ColorMask RGBA

            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Assets/HLSL/PBRComm.hlsl"
            #include "Assets/HLSL/HairComm.hlsl"
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
                float4 positionCS : SV_POSITION;
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
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS = positionWS;
                OUT.tangentWS = TransformObjectToWorldDir(IN.tangentOS);
                OUT.uv = IN.uv;
                OUT.screenPos = ComputeScreenPos(OUT.positionCS);
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

                if (!isFont)
                {
                    N = -N;
                }

                float3 finalColor = HairLighting(B, N, V, data.uv, albedo, light);
                half Roughness = max(tex2D(_RoughnessMap, data.uv) * _Roughness, 0.000001);
                half3 F0 = half3(0.04, 0.04, 0.04);
                half3 inKs = fresnelSchlickRoughness(nv, F0, Roughness);
                half3 inKD = 1 - inKs;
                half3 inDiffuse = SampleSH(N)* albedo * inKD; ///PI;
                output.color = float4(finalColor.xyz + inDiffuse, albedo.a);
                // output.color = float4(finalColor.xyz, albedo.a);
                output.depth = data.positionCS.z;
                if (_DepthPeelingPassCount == 0) //第一次直接渲染
                {
                    return output;
                }
                // return float4(finalColor.xyz + inDiffuse, albedo.a);

                float2 screenUV = data.screenPos.xy / data.screenPos.w;

                float lastDepth = tex2D(_MaxDepth, screenUV).r;
                float pixelDepth = data.positionCS.z;
                if (pixelDepth >= lastDepth)
                {
                    discard;
                }
                return output;
            }
            ENDHLSL
        }
        
         Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

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