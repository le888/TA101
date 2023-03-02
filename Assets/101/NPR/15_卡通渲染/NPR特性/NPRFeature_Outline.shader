Shader "TA/NPR/NPRFeature_Outline"
{
    Properties
    {
        _RampMap ("RampMap", 2D) = "black" {}
        _StepValue("StepValue",Range(0,1)) = 0.5
        _Exp ("_Exp",Float) = 256
        _Intensity ("_Intensity",Float) = 2
        
        
        [Space(30)]
        [Toggle(USETANGENT)]  _UseTanget("使用切线",float) =0
        _OutlineWidth("_OutlineWidth",float) =1
        _OutlineColor("_OutlineColor",Color)=(1,0,0,0)    
       
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 color :  COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

                
            float4 _OutlineColor;
            float _OutlineWidth;
            float _UseTanget;

            v2f vert (appdata v)
            {
                v2f o;
                if(_UseTanget)
                {
                    v.vertex.xyz += v.tangent.xyz*_OutlineWidth*0.01;
                }
                else
                {
                    v.vertex.xyz += v.normal.xyz*_OutlineWidth*0.01;
                }

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
        
            float4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
        
    }
}
