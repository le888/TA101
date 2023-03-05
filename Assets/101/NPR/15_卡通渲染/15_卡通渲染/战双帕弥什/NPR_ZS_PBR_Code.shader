Shader "NPR/NPR_ZS_PBR_Code"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _NormalMap ("_NormalMap", 2D) = "white" {}
        _PBRMixMap ("_PBRMixMap", 2D) = "black" {}
        _LightMap("_LightMap",2D) ="black"{}

        [Space(10)]
        _RoughnessScale("_RoughnessScale",Float) = 1
        _MetallicScale("_MetallicScale",Float) = 1
        _SpecularIntensity("_SpecularIntensity",Float) = 1
        _SpecularStep("_SpecularStep",Float) = 0
        
        [Space(10)]
        _RampOffset ("_RampOffset",Range(-1,1)) =0
        _DarkIntensity("_DarkIntensity",Float) =0.5
        _BrightIntensity("_BrightIntensity",Float) =1
        
        [Space(10)]
        _StepLightWidth("_StepLightWidth",Float) = 0.3
        _StepLightIntensity("_StepLightIntensity",Float) = 1
        
         [Space(10)]
        [KeywordEnum(None,SecondStepLight) ]_UseSecondStepLight("_UseSecondStepLight", Float) = 0
        _RampOffset2 ("_RampOffset2",Range(-1,1)) =0
        _DarkIntensity2("_DarkIntensity2",Float) =0.5
        
        [Space(10)]
        [KeywordEnum(None,GGX,BlinPhong)] _SpecShift("SpecShift", Float) = 1
        _SpecShiftIntensity("_SpecShiftIntensity",Float) =1
        _Shininess("_Shininess",Float) = 1
        _Gloss("_Gloss",Float) = 1
        _Threshold("_Threshold",Float) = 0.2
        
        [Space(10)]
        _RimIntensity("_RimScale",Float) = 1
        _RimWdith("_RimStep",Float) = 0.3
        
        [Space(10)]
        _MaskTest ("_MaskTest",Range(-1,1)) =0
        
         [Space(30)]
        _OulineScale("_OulineScale",Float) =1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //宏定义必须大写，否者定义不管用
            #pragma shader_feature_local _SPECSHIFT_NONE _SPECSHIFT_GGX _SPECSHIFT_BLINPHONG
            #pragma shader_feature_local _USESECONDSTEPLIGHT_NONE _USESECONDSTEPLIGHT_SECONDSTEPLIGHT
        
            // make fog work

            // #include "UnityCG.cginc"
            // // _LightColor0 (declared in UnityLightingCommon.cginc)
            // #include "UnityLightingCommon.cginc" 
            // // #define UNITY_SPECCUBE_LOD_STEPS
            // #include "UnityStandardConfig.cginc"

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "UnityGlobalIllumination.cginc"
            #include "TABrdf.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent :TANGENT;
                float3 normal : NORMAL;
                float4 color : COLOR;
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
                float4 color        : TEXCOORD6;

            };

            sampler2D _MainTex,_NormalMap,_PBRMixMap,_LightMap;
            float _RampOffset,_DarkIntensity,_BrightIntensity;
            float _RampOffset2,_DarkIntensity2,_BrightIntensity2;
            float _SpecularIntensity,_SpecularStep;
            float _RimIntensity,_RimWdith;

            float _Shininess,_Gloss,_Threshold,_SpecShiftIntensity;

            float _RoughnessScale,_MetallicScale;

            float _MaskTest;

            float _StepLightWidth,_StepLightIntensity;

            v2f vert (appdata v)
            {
                v2f o= (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld,v.vertex);
                o.localPostion = v.vertex.xyz;
                o.tangent = UnityObjectToWorldDir(v.tangent);
                o.color = v.color;
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
                float4 VertexColor = i.color;
                float NH = dot(N,H);

//================== PBR  ============================================== //
                float3 BaseMap = tex2D(_MainTex,uv);
                float4 MixMap = tex2D(_PBRMixMap,uv);
                float Metallic = MixMap.r;//金属度
                float Roughness = 1-MixMap.g;//粗糙度
                Metallic *= _MetallicScale;
                Roughness *= _RoughnessScale;
                
                float AO =MixMap.b; //AO
                float GGXMask = MixMap.a;//GGXMask
                // return MixMap.a;
                //材质区分
                float MatMask = 1;
                if(GGXMask <0.2||GGXMask >0.44)
                    MatMask =0;
                if(GGXMask>0.76)
                    MatMask =1;
                // float Leather = 0;
                // if(GGXMask>0.2 && GGXMask <0.44)
                //     Leather =1;
                
                float3 F0 = lerp(0.04,BaseMap,Metallic);

//================== Rim Light  ============================================== //
                float3 RimLight = step(dot(N,V) , _RimWdith ) * _RimIntensity * BaseMap;

//================== Diffuse  ============================================== //
                float3 LightMap = tex2D(_LightMap,uv);
                float RampAdd = LightMap.r;
                float ShadowAO = LightMap.g;
                float SpecularMask = LightMap.b;
                float3 Diffuse = lerp( BaseMap*_DarkIntensity,BaseMap*_BrightIntensity,step( (_RampOffset + RampAdd)*ShadowAO,dot(N,L)));
                //两层裁边漫反射
                #ifdef _USESECONDSTEPLIGHT_SECONDSTEPLIGHT
                float3 Second  = lerp( BaseMap*_DarkIntensity2,Diffuse ,step( (_RampOffset2 + RampAdd)*ShadowAO,dot(N,L)));
                Diffuse = lerp(Diffuse,Second,MatMask);
                #endif

                // return MixMap.a;
//================== Normal Map  ============================================== //
                 float3 NormalMap = UnpackNormal(tex2D(_NormalMap,uv));
                 float3x3 TBN = float3x3(T,B,N);
                 N = normalize( mul (NormalMap,TBN));
                 N = normalize(N);

//================== Specular  ============================================== //
                //Specular
                //Cook-Torrance BRDF
                //float3 Specular = Specular_GGX(N,L,H,V,Roughness,F0) * AO*_SpecularIntensity * GGXMask *MatMask;
                // Specular = step(_SpecularStep,Specular);//对GGX进行裁边操作
                float3 Specular =0;
                
                #ifdef _SPECSHIFT_GGX
                Specular +=  Specular_GGX(N,L,H,V,Roughness,F0) * AO*_SpecularIntensity * GGXMask *MatMask;
                #endif

                #ifdef _SPECSHIFT_BLINPHONG
                StylizedSpecularParam param;
                param.BaseMap = BaseMap;
                param.Normal = N;
                param.Shininess = _Shininess;
                param.Gloss = _Gloss;
                param.Threshold = _Threshold;
                param.dv = T;
                param.du = B;
                Specular +=  StylizedSpecularLight_BlinPhong( param, H)*_SpecShiftIntensity* GGXMask*MatMask;
                #endif

                // return step(_MaskTest,GGXMask);

                float3 StepLight = step(1-_StepLightWidth,NH)*_StepLightIntensity*BaseMap;
                
                float4 FinalColor =0;

                FinalColor.xyz = Diffuse + Specular +RimLight + StepLight;

                return FinalColor;
                
            }
            ENDCG
        }
        
        Pass //"OutLine"
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
                float4 tangent :TANGENT;
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
                 v.vertex.xyz += v.normal.xyz *_OulineScale*0.01*v.vertexColor.a;
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