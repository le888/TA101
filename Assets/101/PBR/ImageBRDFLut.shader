Shader "Hidden/ImageBRDFLut"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        //        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            const float PI = 3.14159265359;
            // ----------------------------------------------------------------------------
            // http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
            // efficient VanDerCorpus calculation.
            float RadicalInverse_VdC(uint bits)
            {
                bits = (bits << 16u) | (bits >> 16u);
                bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
                bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
                bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
                bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
                return float(bits) * 2.3283064365386963e-10; // / 0x100000000
            }

            // ----------------------------------------------------------------------------
            float2 Hammersley(uint i, uint N)
            {
                return float2(float(i) / float(N), RadicalInverse_VdC(i));
            }

            // ----------------------------------------------------------------------------
            float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness)
            {
                float a = roughness * roughness;

                float phi = 2.0 * PI * Xi.x;
                float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
                float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

                // from spherical coordinates to cartesian coordinates - halfway vector
                float3 H;
                H.x = cos(phi) * sinTheta;
                H.y = sin(phi) * sinTheta;
                H.z = cosTheta;

                // from tangent-space H vector to world-space sample vector
                float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
                float3 tangent = normalize(cross(up, N));
                float3 bitangent = cross(N, tangent);

                float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
                return normalize(sampleVec);
            }

            // ----------------------------------------------------------------------------
            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                // note that we use a different k for IBL
                float a = roughness;
                float k = (a * a) / 2.0;

                float nom = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }

            // ----------------------------------------------------------------------------
            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2 = GeometrySchlickGGX(NdotV, roughness);
                float ggx1 = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }

            // ----------------------------------------------------------------------------
            float2 IntegrateBRDF(float NdotV, float roughness)
            {
                float3 V;
                V.x = sqrt(1.0 - NdotV * NdotV);
                V.y = 0.0;
                V.z = NdotV;

                float A = 0.0;
                float B = 0.0;

                float3 N = float3(0.0, 0.0, 1.0);

                const uint SAMPLE_COUNT = 1024u;
                for (uint i = 0u; i < SAMPLE_COUNT; ++i)
                {
                    // generates a sample vector that's biased towards the
                    // preferred alignment direction (importance sampling).
                    float2 Xi = Hammersley(i, SAMPLE_COUNT);
                    float3 H = ImportanceSampleGGX(Xi, N, roughness);
                    float3 L = normalize(2.0 * dot(V, H) * H - V);

                    float NdotL = max(L.z, 0.0);
                    float NdotH = max(H.z, 0.0);
                    float VdotH = max(dot(V, H), 0.0);

                    if (NdotL > 0.0)
                    {
                        float G = GeometrySmith(N, V, L, roughness);
                        float G_Vis = (G * VdotH) / (NdotH * NdotV);
                        float Fc = pow(1.0 - VdotH, 5.0);

                        A += (1.0 - Fc) * G_Vis;
                        B += Fc * G_Vis;
                    }
                }
                A /= float(SAMPLE_COUNT);
                B /= float(SAMPLE_COUNT);
                return float2(A, B);
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
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float4 frag(v2f i) : SV_Target
            {
                // fixed4 col = tex2D(_MainTex, i.uv);
                // // just invert the colors
                // col.rgb = 1 - col.rgb;
                float2 integratedBRDF = IntegrateBRDF(i.uv.x, i.uv.y);
                return float4(integratedBRDF.x,integratedBRDF.y, 0, 0);
            }
            ENDCG
        }
    }
}