Shader "TA/NPR/NPRFeature"
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS:TEXCOORD1;
                float3 positionWS:TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normalWS = UnityObjectToWorldNormal(v.normal);
                o.positionWS = mul( unity_ObjectToWorld,v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            float _StepValue;
            sampler2D _RampMap;

            float _Exp,_Intensity;


            float4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normalWS);
                float3 L = normalize( UnityWorldSpaceLightDir(i.positionWS));
                float3 V = normalize(UnityWorldSpaceViewDir(i.positionWS));
                float3 H = normalize(L+V);

                float NL = dot(N,L);
                float NV = dot(N,V);
                float NH = dot(N,H);
                
                float NL01 = NL*0.5+0.5;
                return NL01;
                // float3 RampMap = tex2D(_RampMap,float2(NL01,0.5));
                // return RampMap.xyzz;
                // float Diffuse = step(1-_StepValue,NL01);

                // return pow(NH,256)*2;
                //BlinPhong
                // float BlinPhong = pow(NH,_Exp)*_Intensity;
                // return step(1-_StepValue,BlinPhong);
                // return step(1-_StepValue,NH);

                float4 RimLight =  pow( 1-NV,8)*2 * float4(1,0,0,0);

                float StepRimLight = step(1-_StepValue,1-NV);

                float StepLight = step(1-_StepValue,NL01);
                float3 StepLight_RampMap = tex2D(_RampMap,float2(NL01,0.5));
                return StepLight_RampMap.xyzz;
            }
            ENDCG
        }
        
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
                // v.vertex.xyz += v.normal.xyz*_OutlineWidth*0.01;
                 // v.color.rg = v.color.rg*2-1;
                 // float b = sqrt(1- v.color.r*v.color.r - v.color.g*v.color.g);    
                 // float3 normalRGB = float3(v.color.rg,b);

                if(_UseTanget)
                {
                    v.vertex.xyz += v.tangent.xyz*_OutlineWidth*0.01;
                }
                else
                {
                    v.vertex.xyz += normalize( v.color.rgb*2-1)*_OutlineWidth*0.01;
                }
                
                // v.vertex.xyz += v.tangent.xyz*_OutlineWidth*0.01;
                // v.vertex.xyz += v.normal.xyz*_OutlineWidth*0.01;
                // v.vertex.xyz += normalRGB.xyz*_OutlineWidth*0.01;
                // v.vertex.xyz += (v.color.rgb*2-1)*_OutlineWidth*0.01;
                
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
