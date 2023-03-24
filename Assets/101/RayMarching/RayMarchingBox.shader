Shader "Hidden/RayMarchingBox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        //        Cull Off ZWrite Off ZTest Always
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        Pass
        {

            //            Tags
            //            {
            //                "LightMode" = "RayMarching"
            //            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }


            float rayMarching(float3 cameraPos, float3 ray, float start, float end)
            {
                float nowDepth = start;
                for (int i = 0; i < 100; i++)
                {
                    float dist = sdSphere(cameraPos + nowDepth * ray, 0.1);
                    if (dist < 0.001)
                        return nowDepth;
                    nowDepth += dist;
                    if (dist > end)
                        return end;
                }
                return end;
            }

            float3 getRay(float viewAngle, float2 screenSize, float2 pos)
            {
                float2 up = pos - screenSize / 2.0;
                float z = screenSize.y / tan(radians(viewAngle) / 2.0);
                float3 ray = normalize(float3(up, -z));
                return ray;
            }


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

            fixed4 frag(v2f i) : SV_Target
            {
                float fov = 45;
                float3 ray = getRay(fov, _ScreenParams.xy, i.vertex.xy);
                float3 eye = float3(0.0, 0.0, 1); //摄像机位置
                float dist = rayMarching(eye, ray, 0, 100);

                fixed4 color = fixed4(0.0, 0.0, 0.0, 1.0);
                if (dist < 100 - 0.001)
                    color = fixed4(1.0, 0.0, 0.0, 1.0);
                return color;
            }
            ENDCG
        }
    }
}