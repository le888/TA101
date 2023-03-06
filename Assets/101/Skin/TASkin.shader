// This shader fills the mesh shape with a color predefined in the code.
Shader "TASkin"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        [MainTexture]_BaseMap("Base (RGB)", 2D) = "white" {}
        [Normal]_BumpMap("Normal (RGB)", 2D) = "bump" {}
        //        _MetallicMap("Metallic (R)", 2D) = "white" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.5
        _CurvatureMap("Curvature (R)", 2D) = "white" {}
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
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {
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
            sampler2D _BumpMap;
            // sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            sampler2D _CurvatureMap;
            // float _Metallic;
            sampler2D _MacoNormalMap;
            float4 _MacoNormalMap_ST;
            float _MacoNormalWeight;
            //Physically based Shading
            //Cook-Torrance BRDF

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

                float3 normalTS = SafeNormalize(UnpackNormal(tex2D(_BumpMap, data.uv)));
                float3 detailNormalTS = SafeNormalize(
                    UnpackNormal(tex2D(_MacoNormalMap, data.uv * _MacoNormalMap_ST.xy + _MacoNormalMap_ST.zw)));
                float3 MacoNormal = SafeNormalize(detailNormalTS);
                // return detailNormalTS.xyzz;
                normalTS = lerp(normalTS, BlendNormalRNM(normalTS, MacoNormal), _MacoNormalWeight);
                normalTS = SafeNormalize(normalTS);
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
                float3 albedo = tex2D(_BaseMap, data.uv) * _BaseColor.rgb;
                float curvalue = 0.01 * length(fwidth(N)) / length(fwidth(data.positionWS));
                curvalue = saturate(curvalue);
                float curvalueMapValue = tex2D(_CurvatureMap, data.uv).r;
                float3 lutbrdf = PreIntegratedSkinWithCurveApprox(nl01, curvalue);
                float3 directLightDiffuse = lutbrdf * light.color * albedo * light.distanceAttenuation * light.
                    shadowAttenuation;
                float F = F_Schlickss(0.028,N, v); //皮肤的高光项，0.028 经验值
                directLightDiffuse *= (1 - F);
                // return F.xxxx;
                half3 inDiffuse = SampleSH(meshNormal) * albedo;


                half Roughness = max(tex2D(_RoughnessMap, data.uv) * _Roughness, 0.000001);
                // half Roughness =  tex2D(_RoughnessMap,data.uv) * _Roughness;
                float specular = KS_Skin_Specular(N, l, v, Roughness, 1);

                float3 finalColor = directLightDiffuse + inDiffuse + specular;
                return finalColor.xyzz;
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