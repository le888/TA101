Shader "Unlit/preSkin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Library/PackageCache/com.unity.render-pipelines.core@14.0.11/ShaderLibrary/Macros.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float Gaussian(float v, float r)
            {
                return 1.0 / sqrt(2.0 * PI * v) * exp(-(r * r) / (2 * v));
            }

            float3 Scatter(float r)
            {
                // Coefficients from GPU Gems 3 - '`Advanced Skin Rendering
                return Gaussian(0.0064 * 1.414, r) * float3
                    (0.233, 0.455, 0.649) +
                    Gaussian(0.0484 * 1.414, r) * float3
                    (0.100, 0.336, 0.344) +
                    Gaussian(0.1870 * 1.414, r) * float3
                    (0.118, 0.198, 0.000) +
                    Gaussian(0.5670 * 1.414, r) * float3
                    (0.113, 0.007, 0.007) +
                    Gaussian(1.9900 * 1.414, r) * float3
                    (0.358, 0.004, 0.000) +
                    Gaussian(7.4100 * 1.414, r) * float3
                    (0.078, 0.000, 0.000);
            }

            float inc = 0.1;

            float3 integrateDiffuseScatteringOnRing(float cosTheta, float skinRadius)
            {
                // Angle from lighting direction.
                float theta = acos(cosTheta);
                float3 totalWeights = 0;
                float3 totalLight = 0;
                float a = -(PI / 2);
                while (a <= (PI / 2))
                    while (a <= (PI / 2))
                    {
                        float sampleAngle = theta + a;
                        float diffuse = saturate(cos(sampleAngle));
                        float sampleDist = abs(2.0 * skinRadius * sin(a * 0.5));
                        // Distance.
                        float3 weights = Scatter(sampleDist);
                        // Profile Weight.
                        totalWeights += weights;
                        totalLight += diffuse * weights;
                        a += inc;
                    }
                return totalLight / totalWeights;
            }

            float3 integrateShadowScattering(float penumbraLocation,
                                             float penumbraWidth)
            {
                float3 totalWeights = 0;
                float3 totalLight = 0;
                float a = -PROFILE_WIDTH;
                while (a <= PROFILE_WIDTH)
                    while (a <= PROFILE_WIDTH)
                    {
                        float light = newPenumbra(penumbraLocation + a /penumbraWidth);
                        float sampleDist = abs(a);
                        float3 weights = Scatter(sampleDist);
                        totalWeights += weights;
                        totalLight += light * weights;
                        a += inc;
                    }
                return totalLight / totalWeights;
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
                // return half4(integrateDiffuseScatteringOnRing(i.uv.x, 1), 1);
            }
            ENDCG
        }
    }
}