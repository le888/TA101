Shader "NPR/OutLine"
{
    Properties
    {
        _MainTex("_MainTex",2D) ="white"{}
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "LightMode"="ForwardBase" "Queue" = "Geometry"
        }
        
        Pass
        {
            Name "BASE"
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            sampler2D _MainTex;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return tex2D(_MainTex,i.uv);
            }
            ENDCG
        }

        Pass
        {
            
            Name "NORMAL"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 normal :NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal.xyz *_OulineScale*0.01;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
        
        Pass
        {
            
            Name "COLOR"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 normal :NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;

                float3 smoothNormal = v.vertexColor.rgb*2 -1;
                v.vertex.xyz += smoothNormal.xyz *_OulineScale*0.01;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
        
        Pass
        {
            
            Name "TANGENT"
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
          
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 vertexColor : COLOR;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION; 
                float2 uv : TEXCOORD0;
            };

            float _OulineScale;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                v.vertex.xyz += v.tangent.xyz *_OulineScale*0.01;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
      
            float4 frag(v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
}