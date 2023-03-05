Shader "NPR/NPR_ZS_Hair_Code"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _LightMap("_LightMap",2D) ="black"{}
        _RampOffset ("_RampOffset",Range(-1,1)) =0
        _DarkIntensity("_DarkIntensity",Range(0,1)) =0.5
        _BrightIntensity("_BrightIntensity",Float) =1
        
        [Space(10)]
        _HairSpecularExp("_HairSpecularExp",Float) =1
        _HairSpecularIntensity("_HairSpecularIntensity",Float) =1
        
        [Space(10)]
        _RimIntensity("_RimScale",Float) = 1
        _RimWdith("_RimStep",Float) = 0.3
        
        [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
        
        [Space(30)]
        _SpecularRange("_SpecularRange",Range(0,5)) =1
        _SpecularIntensity("_SpecularIntensity",Range(0,5)) =1
        _SpecularDarkIntensity("_SpecularDarkIntensity",Range(0,5)) =1
        _SpecularNVExp("_SpecularNVExp",Float) =1
        _SpecularNVIntensity("_SpecularNVIntensity",Float) =1
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
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 tangent      : TEXCOORD1;
                float3 bitangent    : TEXCOORD2; 
                float3 normal       : TEXCOORD3; 
                float3 worldPosition: TEXCOORD4;
                float3 localPostion : TEXCOORD5;
            };

            sampler2D _MainTex,_NormalMap,_MixMap,_LightMap;
            float _RampOffset,_DarkIntensity,_BrightIntensity;
            float _HairSpecularExp,_HairSpecularIntensity;
            float _RimIntensity,_RimWdith;

            float _SpecularRange,_SpecularNVExp,_SpecularNVIntensity,_SpecularIntensity,_SpecularDarkIntensity;

            v2f vert (appdata v)
            {
                v2f o= (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.localPostion = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                //o.bitangent = cross(o.normal,o.tangent) * v.tangent.w;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                //Variable
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                float3 B = normalize( cross(N,T));
                // float3 B = normalize( i.bitangent);
                float3 L = normalize( UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize( UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V+L);
                float2 uv = i.uv;
                float NV  = dot(N,V);
                float NV01 = NV*0.5+0.5 +0.01;

//================== PBR  ============================================== //
                float3 BaseMap = tex2D(_MainTex,uv);

//================== Rim Light  ============================================== //
                float3 RimLight = step(dot(N,V) , _RimWdith ) * _RimIntensity * BaseMap;

//================== Diffuse  ============================================== //
                float3 LightMap = tex2D(_LightMap,uv);
                float RampAdd = 0;
                float ShadowAO = LightMap.g>0.01;
                float Threshold = step( (_RampOffset + RampAdd),dot(N,L)) *ShadowAO;
                float3 Diffuse = lerp( BaseMap*_DarkIntensity,BaseMap*_BrightIntensity,Threshold);
                
                float SpecularMask = LightMap.r;
                // return LightMap.r;
                // return SpecularMask;
                // return NV;
                float3 Specular = step( pow( 1-NV,_SpecularNVExp)*_SpecularNVIntensity,SpecularMask*_SpecularRange)*(SpecularMask>0.1);
                Specular = lerp(_SpecularDarkIntensity,_SpecularIntensity,Threshold)*Specular*BaseMap;
               

//================== Direct Light  ============================================== //
                //Specular
                // float3 Specular = pow(saturate( dot(N,H)) , _HairSpecularExp ) * _HairSpecularIntensity *SpecularMask;
                float4 FinalColor =0;
                
                FinalColor.xyz = Diffuse + Specular +RimLight;

                return FinalColor*1.2;
                
            }
            ENDCG
        }
        
           //OUTLINE
        UsePass "NPR/NPR_ZS_PBR_Code/NORMAL"
    }
    Fallback "Diffuse"
}