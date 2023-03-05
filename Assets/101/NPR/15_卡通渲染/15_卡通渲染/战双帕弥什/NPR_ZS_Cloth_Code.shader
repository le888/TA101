Shader "NPR/NPR_ZS_Cloth_Code"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "white" {}
        _LightMap("_LightMap",2D) ="black"{}
        _LightThreshold("_LightThreshold",Range(-2,2))=1
        _RampOffset ("_RampOffset",Range(-1,1)) =0
        _DarkIntensity("_DarkIntensity",Range(0,1)) =0.5
        _BrightIntensity("_BrightIntensity",Float) =1
        _Roughness("_Roughness",Range(0,1)) =0.5
        _Metallic("_Metallic",Range(0,1)) =0.1
        _SpecularIntensity("_SpecularIntensity",Float) =1
        _RimExp("_RimExp",Float) = 4

        [Space(10)]
        _RimIntensity("_RimScale",Float) = 1
        _RimWdith("_RimStep",Float) = 0.3

        [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" 
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //宏定义必须大写，否者定义不管用
            #pragma multi_compile MODE_VALUE MODE_TEX

            #include "UnityCG.cginc"
            #include "TABrdf.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tangent : TEXCOORD1;
                float3 bitangent : TEXCOORD2;
                float3 normal : TEXCOORD3;
                float3 worldPosition: TEXCOORD4;
                float3 localPostion : TEXCOORD5;
            };

            sampler2D _MainTex, _NormalMap, _MixMap, _LightMap;
            float _RampOffset, _DarkIntensity, _BrightIntensity,_LightThreshold;
            float _Roughness, _Metallic, _SpecularIntensity;
            float _RimIntensity, _RimWdith;
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.localPostion = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                //o.bitangent = cross(o.normal,o.tangent) * v.tangent.w;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                //Variable
                float3 T = normalize(i.tangent);
                float3 N = normalize(i.normal);
                float3 B = normalize(cross(N, T));
                // float3 B = normalize( i.bitangent);
                float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition.xyz));
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPosition.xyz));
                float3 H = normalize(V + L);
                float2 uv = i.uv;
                
                float NL = dot(N,L);
                float NV    = dot(N,V);
                float NL01 = NL*0.5+0.5;
                
                //================== PBR  ============================================== //
                float4 BaseMap = tex2D(_MainTex, uv);//BaseMap.a无信息
                float Roughness = _Roughness;
                float Metallic = _Metallic;
                float3 F0 = lerp(0.04, BaseMap, Metallic);

                //================== Rim Light  ============================================== //
                float3 RimLight = step(NV, _RimWdith) * _RimIntensity * BaseMap;

                //================== Diffuse  ============================================== //
                float4 LightMap = tex2D(_LightMap, uv);// return LightMap.a;
                float RampOffsetMask = LightMap.r*2-1;     //Rampofsset,控制感光
                float ShadowAO = LightMap.g > 0.001;  //常暗区域
                float SpecularMask = LightMap.b;    //高光mask
                float3 BrightSide = BaseMap * _BrightIntensity;
                float3 DarkSide = BaseMap * _DarkIntensity;
                
                float Threshold = step(_LightThreshold,NL01+_RampOffset+RampOffsetMask)*ShadowAO;
                float3 Diffuse = lerp(DarkSide,BrightSide, Threshold);

                //================== Normal Map  ============================================== //
                float3 NormalMap = UnpackNormal(tex2D(_NormalMap, uv)); //NormalMap* 2 - 1;
                //TBN矩阵:将世界坐标转到Tangent坐标
		        //TBN是正交矩阵，正交矩阵的逆等于其转置
                float3x3 TBN = float3x3(T, B, N);
                // ITBN = inverse(TBN);
                // N = normalize(mul(ITBN, NormalMap));//将NormalMap 从Tangent坐标转到世界坐标
                N = normalize(mul(NormalMap, TBN));//将NormalMap 从Tangent坐标转到世界坐标
                
                //================== Direct Light  ============================================== //
                //Specular
                //Cook-Torrance BRDF
                float3 Specular = Specular_GGX(N, L, H, V, Roughness, F0) * SpecularMask * _SpecularIntensity;
                float4 FinalColor = 0;
                FinalColor.xyz = Diffuse + Specular + RimLight;

                return FinalColor*1.2;
            }
            ENDCG
        }

        //OUTLINE
        UsePass "NPR/NPR_ZS_PBR_Code/NORMAL"
    }
    Fallback "Diffuse"
}