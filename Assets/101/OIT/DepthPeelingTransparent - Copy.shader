Shader "Unlit/DeptPeelingTransparent"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Normal ("Normal Texture", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Roughness ("Roughness", Range(0, 10)) = 0
        _F0("Fresnel 0", Range(0, 1)) = 0.2
        _FresnelExponent("Fresnel Exponent", Range(1, 64)) = 5
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue"="Transparent"
        }

        HLSLINCLUDE

        #include "UnityCG.cginc"

        float4 _Color;
        sampler2D _MainTex;
		sampler2D _Normal;
		float4 _Normal_ST;
        float _BumpScale;
        
        float4 _Roughness;
        float _F0;
        float _FresnelExponent;

        struct v2f
        {
            float4 positionCS: SV_POSITION;
            float2 uv : TEXCOORD0;
	        float3 worldPos: TEXCOORD1;
	        float3 t2w0: TEXCOORD2;
	        float3 t2w1: TEXCOORD3;
	        float3 t2w2: TEXCOORD4;
            float4 screenPos : TEXCOORD5;
        };

        v2f DepthPeelingVertex(appdata_full i)
        {
            v2f o;
	        o.positionCS = UnityObjectToClipPos(i.vertex);
            o.uv = i.texcoord;
            o.worldPos = mul(unity_ObjectToWorld, i.vertex);
            float3 worldNormal = UnityObjectToWorldNormal(i.normal);
	        float3 worldTangent = UnityObjectToWorldDir(i.tangent.xyz);
	        float3 worldBinormal = cross(worldNormal, worldTangent) * i.tangent.w;
	        o.t2w0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
	        o.t2w1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
	        o.t2w2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
            o.screenPos = ComputeScreenPos(o.positionCS);
            return o;
        }


        inline float3 tangentSpaceToWorld(v2f i, float3 v)
        {
            return float3(dot(v, i.t2w0.xyz), dot(v, i.t2w1.xyz), dot(v, i.t2w2.xyz));
        }

        inline float3 fresnelFunc(float f0, float nv, float p) {
	        return f0 + (1 - f0) * pow(1 - nv, p);
        }

        float4 RenderPixel(v2f i)
        {
            float4 packNormal = tex2D(_Normal, i.uv); 
			float3 normal = UnpackNormal(packNormal);
            normal.xy *= _BumpScale;
            normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
            normal = normalize(tangentSpaceToWorld(i, normal));
            
			float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            float3 reflectDir = normalize(reflect(-viewDir, normal));
            // float3 reflection = texCUBE(unity_SpecCube0, reflectDir);
            float3 reflection = 1;
            float nl = dot(viewDir, normal) > 0 ? dot(viewDir, normal) : dot(viewDir, -normal);
            float fresnel = saturate(fresnelFunc(_F0, nl, _FresnelExponent));
            float4 color = tex2D(_MainTex, i.uv).rgba * _Color.rgba;
            /*color = dot(viewDir, normal) > 0
                ? lerp(color, float4(reflection, 1), fresnel)
                : color;*/
            //color = lerp(color, float4(reflection, 1), fresnel); 
            color.rgb = color.rgb * color.a * (1 - fresnel) + reflection.rgb * fresnel;
            // color.rgb = color.rgb * i.uv.x;
            color.a = lerp(color.a, 1, fresnel);
            
            return color;
        }
        
        #include "DepthPeelingCommon.hlsl"
        SETUP_DEPTH_PEELING

        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode" = "DepthPeelingPass"
            }

            ZWrite On
            Cull Off

            HLSLPROGRAM

            #pragma vertex DepthPeelingVertex
            #pragma fragment DepthPeelingPixel

            ENDHLSL
        }
        
    }
}