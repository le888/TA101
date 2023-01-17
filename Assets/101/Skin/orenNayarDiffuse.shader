Shader "Unlit/orenNayarDiffuse"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _roughness ("Roughness", Range(0,1)) = 0.5
        _albedo ("Albedo", Color) = (1,1,1,1)
        [Toggle]_useLambert ("Use Lambert", Float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

            #define PI 3.14159265


            float OrenNayarDiffuse(
                float3 lightDirection,
                float3 viewDirection,
                float3 surfaceNormal,
                float roughness,
                float albedo)
            {
                float LdotV = dot(lightDirection, viewDirection);
                float NdotL = dot(lightDirection, surfaceNormal);
                float NdotV = dot(surfaceNormal, viewDirection);

                float s = LdotV - NdotL * NdotV;
                float t = lerp(1.0, max(NdotL, NdotV), step(0.0, s));

                float sigma2 = roughness * roughness;
                float A = 1.0 + sigma2 * (albedo / (sigma2 + 0.13) + 0.5 / (sigma2 + 0.33));
                float B = 0.45 * sigma2 / (sigma2 + 0.09);

                return albedo * max(0.0, NdotL) * (A + B * s / t) / PI;
            }

///////////////////////////beckmann
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
            float3 fresnelReflectance(float3 N, float3 V,float3 F0)
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
                sampler2D beckmannTex)
            {
                float result = 0.0;
                float ndotl = dot(N, L);
                if (ndotl > 0.0)
                {
                    float3 h = L + V; // Unnormalized half-way vector
                    float3 H = normalize(h);
                    float ndoth = dot(N, H);
                    // float PH = pow(2.0 * tex2D(beckmannTex, float2(ndoth, m)), 10.0);
                    float PH = pow(2.0 * KSTextureCompute(float2(ndoth, m)), 10.0);
                    float F = fresnelReflectance(N, V, 0.028);
                    float frSpec = max(PH * F / dot(h, h), 0);
                    result = ndotl * rho_s * frSpec; // BRDF * dot(N,L) * rho_s
                }
                return result;
            }


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal: NORMAL;
                float3 positionWS : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _roughness;
            float4 _albedo;
            float _useLambert;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.positionWS = TransformObjectToWorld(v.vertex);
                return o;
            }


            float4 frag(v2f i) : SV_Target
            {
                Light light = GetMainLight();
                float3 L = SafeNormalize(light.direction);
                float3 V = SafeNormalize(_WorldSpaceCameraPos.xyz - i.positionWS);
                float3 N = SafeNormalize(i.normal);
                float3 H = SafeNormalize(L + V);
                // float nl = dot(N, L) ;
                // float lamberDiffuse = nl * _albedo/PI ;
                // float orenNayarDiffuse = OrenNayarDiffuse(L, V, N, _roughness, _albedo);
                // return _useLambert == 1 ? lamberDiffuse.xxxx : orenNayarDiffuse.xxxx;

                float beckmann = KSTextureCompute(i.uv);
                float result =  KS_Skin_Specular(N, L, V, _roughness, 1, _MainTex);
                return result.xxxx;
                return beckmann.xxxx;

                // // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                // return col;
            }
            ENDHLSL
        }
    }
}