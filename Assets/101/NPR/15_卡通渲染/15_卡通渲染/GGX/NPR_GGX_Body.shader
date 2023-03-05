Shader "NPR/GGX_Body"
{
    Properties
    {
        _MainTex ("BaseMap", 2D) = "white" {}
        _TintMap ("TintMap", 2D) = "white" {}
        _LightMap ("LightMap", 2D) = "white" {}
        
        
        
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }

        /*
        //Transparent Setup
         Tags { "Queue"="Transparent"  "RenderType"="Transparent" "LightMode"="ForwardBase"}
         Blend SrcAlpha OneMinusSrcAlpha
        */

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fullforwardshadows
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityGlobalIllumination.cginc"
            #include "AutoLight.cginc"
            // #include "NPRBrdf.cginc" 


            #ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
            //only defining to not throw compilation error over Unity 5.5
            #define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
            #endif
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition : TEXCOORD4;
                float3 localPosition : TEXCOORD5;
                float3 localNormal : TEXCOORD6;
                float4 vertexColor : TEXCOORD7;
                float2 uv2 : TEXCOORD8;
                LIGHTING_COORDS(9, 10)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.uv2 = v.uv2;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.localPosition = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;
                o.localNormal = v.normal;
                o.vertexColor = v.vertexColor;
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float4 frag(v2f i) : SV_Target
            {
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                //float3 B = normalize( cross(N,T));
                float3 B = normalize(i.bitangent);
                float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V + L);
                float2 uv = i.uv;
                float2 uv2 = i.uv2;

                // return float4(uv2,0,0);
                float4 vertexColor = i.vertexColor;
                // return vertexColor.xyzz;
                float HV = dot(H, V);
                float NV = dot(N, V);
                float NL = dot(N, L);
                float NH = dot(N, H);

                float4 FinalColor = 0;
                float4 BaseColor = tex2D(_MainTex, uv);

                
                FinalColor.rgb = BaseColor.rgb;

                // float shadow = SHADOW_ATTENUATION(i);
                

                
                return FinalColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}