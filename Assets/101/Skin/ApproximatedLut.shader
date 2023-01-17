Shader "Unlit/ApproximatedLut"
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            float3 ApproximateLutCurveData(half NdotL, half curvature)
            {
                NdotL = mad(NdotL, 0.5, 0.5); // map to 0 to 1 range
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

            float3 testCode(half curvature)
            {
                float curva = (1.0 / mad(curvature, 0.5 - 0.0625, 0.0625) - 2.0) / (16.0 - 2.0);
                // curvature is within [0, 1] remap to r distance 2 to 16
                float oneMinusCurva = 1.0 - curva;
                float3 zh0;
                {
                    float2 remappedCurva = 1.0 - saturate(curva * float2(3.0, 2.7));
                    remappedCurva *= remappedCurva;
                    remappedCurva *= remappedCurva;
                    float3 multiplier = float3(1.0 / mad(curva, 3.2, 0.4), remappedCurva.x, remappedCurva.y);
                    zh0 = mad(multiplier, float3(0.061659, 0.00991683, 0.003783), float3(0.868938, 0.885506, 0.885400));
                }
                float3 zh1;
                {
                    float remappedCurva = 1.0 - saturate(curva * 2.7);
                    float3 lowerLine = mad(float3(0.197573092, 0.0117447875, 0.0040980375),
                                           (1.0f - remappedCurva * remappedCurva * remappedCurva),
                                           float3(0.7672169, 1.009236, 1.017741));
                    float3 upperLine = float3(1.018366, 1.022107, 1.022232);
                    zh1 = lerp(upperLine, lowerLine, oneMinusCurva * oneMinusCurva);
                }

                float remapMin = 0.75;
                float remapMax = 1.05;
                zh0 = zh0 * (remapMax - remapMin) + remapMin;
                zh1 = zh1 * (remapMax - remapMin) + remapMin;
                return zh1;
            }

            

            fixed4 frag(v2f i) : SV_Target
            {
                float3 color = ApproximateLutCurveData(i.uv.x * 2 - 1, i.uv.y).xyzz;
                // float3 color = testCode(i.uv.x).xyzz;
                return color.xyzz;
                
                // sample the texture
                // fixed4 col = tex2D(_MainTex, i.uv);
                // // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                // return col;
            }
            ENDCG
        }
    }
}