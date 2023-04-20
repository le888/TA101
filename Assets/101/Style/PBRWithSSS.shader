// This shader fills the mesh shape with a color predefined in the code.
Shader "PBRWithSSS"
{
    // The properties block of the Unity shader. In this example this block is empty
    // because the output color is predefined in the fragment shader code.
    Properties
    {
        _BaseColor("Color", Color) = (1,1,1,1)
        _BaseMap("Base (RGB)", 2D) = "white" {}
        [Normal]_BumpMap("Normal (RGB)", 2D) = "bump" {}
        _MetallicMap("Metallic (R)", 2D) = "white" {}
        _RoughnessMap("Roughness (R)", 2D) = "white" {}
        _Roughness("Roughness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.5
        _BRDF("BRDF", 2d) = "white" {}
        
         [Space(15)]
        _ShallowDistance("Shallow Distance",Float) = 3
        _DeepDistance("Deep Distance",Float) = 15
        _Density("Density",Range(0,1)) =1
        _ShadowColor("Shdow Color", Color) = (0,0,0,1)
        _DeepColor("Deep Color", Color) = (1,1,1,1)
        
         [Space(15)]
        _FoamWidth("Foam Width",Range(0,1)) = 0.95
        _FoamSpeed("Foam Speed",Float) = 1
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
            // 透明度混合
            Blend SrcAlpha OneminusSrcAlpha
            // The HLSL code block. Unity SRP uses the HLSL language.
            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Assets/HLSL/PBRComm.hlsl"
            float4 _BaseColor;
            sampler2D _BRDF;
            sampler2D _BaseMap;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            sampler2D _MetallicMap;
            sampler2D _RoughnessMap;
            float _Roughness;
            float _Metallic;
            float4 _playerPos;
            float _FoamWidth, _FoamSpeed;
             float _DeepDistance,_ShallowDistance,_Density;
            float4 _ShadowColor,_DeepColor;
            //Physically based Shading

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
                float4 screenUV : TEXCOORD4;
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
                OUT.screenUV  =  ComputeScreenPos(OUT.positionHCS);
                return OUT;
            }

            // The fragment shader definition.
            half4 frag(Varyings data) : SV_Target
            {
                Light light = GetMainLight();
                float3 L = SafeNormalize(light.direction);
                float3 N = SafeNormalize(data.normalWS);
                float3 T = SafeNormalize(data.tangentWS);
                float3 B = cross(N, T);
                float3x3 TBN = float3x3(T, B, N);

                float2 normalUV = data.uv * _BumpMap_ST.xy + _BumpMap_ST.zw;
                normalUV.y += _Time.y * 0.05;
                float3 n = SafeNormalize(UnpackNormal(tex2D(_BumpMap, normalUV)));
                n = mul(n, TBN);
                // return  n.xyzz;
                float3 V = SafeNormalize(_WorldSpaceCameraPos.xyz - data.positionWS);
                float3 H = SafeNormalize(L + V);
                float nv = saturate(dot(n, V));
                float nl = saturate(dot(n, L));
                // /////直接光照////////////////
                // ////diffuse
                //
                float4 baseColor = tex2D(_BaseMap, data.uv) * _BaseColor;
                float3 albedo = baseColor.rgb;


                half3 F0 = half3(0.04, 0.04, 0.04);
                _Metallic = tex2D(_MetallicMap, data.uv) * _Metallic;
                F0 = lerp(F0, albedo, _Metallic);

                half Roughness = tex2D(_RoughnessMap, data.uv) * _Roughness;

                float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                float3 directColor = DirectCookTorranceBRDF(n, V, L, F0, Roughness, _Metallic, albedo, radiance);

                // #if defined(_ADDITIONAL_LIGHTS)
                uint pixelLightCount = GetAdditionalLightsCount();
                uint meshRenderingLayers = GetMeshRenderingLightLayer();
                LIGHT_LOOP_BEGIN(pixelLightCount)
                    Light light = GetAdditionalLight(lightIndex, data.positionWS, half4(1, 1, 1, 1)); //unityFunction
                    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
                    {
                        float3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;
                        directColor += DirectCookTorranceBRDF(n, V, light.direction, F0, Roughness, _Metallic, albedo,
                                                              radiance);
                    }
                LIGHT_LOOP_END
                // #endif


                //间接光照,SampleSH 球谐函数/////////////////////////////////////////////////////////////////////////////
                half3 F = fresnelSchlickRoughness(nv, F0, Roughness);
                half3 kS = F;
                half3 KD = 1 - kS;
                KD *= 1 - _Metallic;
                half3 diffuse = SampleSH(n) * albedo;
                // return  inDiffuse.xyzz;
                //间接高光，split sum approximation   一部分和diffuse一样加了对环境贴图卷积，不过这次用粗糙度区分了mipmap
                half mip = PerceptualRoughnessToMipmapLevel(Roughness); //unity 最大值7层mipmap
                half3 reflectVector = reflect(-V, n);
                half4 encodedIrradiance = half4(
                    SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));
                real3 inspecPart1 = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                // float2 brdf = tex2D(_BRDF, float2(nv, Roughness)).rg;
                float2 brdf = EnvBRDFApprox(Roughness, nv);
                half3 inspectPart2 = (F * brdf.x + brdf.y);
                half3 specular = inspecPart1 * inspectPart2;
                float3 ambient = (diffuse * KD + specular);
                float3 finalColor = ambient + directColor.xyz;


                //===================== SSR  屏幕空间反射=======================================================================
                float4 fresnel = (pow(1 - V.y, 2));
                float3 reflection = 0;
                // #ifdef _REFTYPE_SSR
                float4 ssr = WaterSSR(data.positionWS, lerp(float3(0, 1, 0), n, 0.01), _WorldSpaceCameraPos);
                reflection = ssr.rgb * fresnel * 2;
                // #endif
                
                //===================== Depth Fade 根据深度颜色变换 =======================================================================
                float2 screenUV = data.screenUV.xy / data.screenUV.w;//直接在VS中做了除法，效果会出错
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float3 depthWorldPosition = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);

                float depthDistance = length(depthWorldPosition - data.positionWS);
                float depthFade = saturate( depthDistance/_DeepDistance);
                finalColor *= lerp(_ShadowColor,_DeepColor,depthFade);
                //===================== Foam 边缘水花=======================================================================
                // #ifdef USE_FOAM
                // return _NoiseMap.Sample(sampler_NoiseMap,  input.positionWS.xz*0.1 + float2(_Time.x*2,0));
                float foamDistance = 1 - saturate(depthDistance / 2);
                float foamDynamic = 0.5 * step(
                        _FoamWidth, frac(foamDistance + _Time.y * 0.1 * _FoamSpeed)) * foamDistance *
                    foamDistance;
                float foamStatic = 0.5 * step(_FoamWidth, frac(foamDistance )) * foamDistance *
                    foamDistance;
                float foam = max(foamDynamic, foamStatic);
                // finalColor *= lerp(_ShadowColor,_DeepColor,depthFade);
                finalColor += foam;
                // #endif


                // finalColor = lerp(reflection,finalColor,kS);
                finalColor = lerp(finalColor, reflection, saturate(fresnel)) + fresnel * 0.1;
                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
    }
}