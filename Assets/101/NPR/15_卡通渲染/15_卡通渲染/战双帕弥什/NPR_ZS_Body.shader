// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "NPR_ZS_Body"
{
	Properties
	{
		[KeywordEnum(Cloth,Skin,Face,Hair,Debug)] _Type("Type", Float) = 0
		[KeywordEnum(BaseColor,NormalMap,VC_R,VC_G,VC_B,L_R,L_G,L_B,L_A)] _Debug("Debug", Float) = 0
		_MainTex("MainTex", 2D) = "white" {}
		[Normal]_NormalMap("NormalMap", 2D) = "white" {}
		_RampOffset("RampOffset", Range( -1 , 1)) = 0
		_HairRampOffset("HairRampOffset", Range( -1 , 1)) = 0
		_DarkIntensity("DarkIntensity", Range( 0 , 1)) = 0.5
		_BrightIntensity("BrightIntensity", Range( 0 , 10)) = 1
		_SkinRamp("SkinRamp", 2D) = "white" {}
		_FaceRamp("FaceRamp", 2D) = "white" {}
		_LightMap("LightMap", 2D) = "white" {}
		_HairLightMap("HairLightMap", 2D) = "white" {}
		_HairSpecularExponent("HairSpecularExponent", Float) = 4
		_HairSpecularScale("HairSpecularScale", Float) = 1
		_FaceLightMap("FaceLightMap", 2D) = "black" {}
		_SpecularExp("SpecularExp", Float) = 0
		_SpecularScale("SpecularScale", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		 _OulineScale("_OulineScale",Float) =0.1
        _OutlineColor ("_OutlineColor",Color) = (0,0,0,0)
	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _TYPE_CLOTH _TYPE_SKIN _TYPE_FACE _TYPE_HAIR _TYPE_DEBUG
			#pragma shader_feature_local _DEBUG_BASECOLOR _DEBUG_NORMALMAP _DEBUG_VC_R _DEBUG_VC_G _DEBUG_VC_B _DEBUG_L_R _DEBUG_L_G _DEBUG_L_B _DEBUG_L_A


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float3 ase_normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float _DarkIntensity;
			uniform float _BrightIntensity;
			uniform sampler2D _LightMap;
			uniform float4 _LightMap_ST;
			uniform float _RampOffset;
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			uniform float _SpecularExp;
			uniform float _SpecularScale;
			uniform sampler2D _SkinRamp;
			uniform sampler2D _FaceRamp;
			uniform sampler2D _FaceLightMap;
			uniform float4 _FaceLightMap_ST;
			uniform sampler2D _HairLightMap;
			uniform float4 _HairLightMap_ST;
			uniform float _HairSpecularExponent;
			uniform float _HairSpecularScale;
			uniform float _HairRampOffset;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 ase_worldTangent = UnityObjectToWorldDir(v.ase_tangent);
				o.ase_texcoord2.xyz = ase_worldTangent;
				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord4.xyz = ase_worldBitangent;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 uv_MainTex = i.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode2 = tex2D( _MainTex, uv_MainTex );
				float4 DarkColor19 = ( tex2DNode2 * _DarkIntensity );
				float4 BaseColor16 = ( tex2DNode2 * _BrightIntensity );
				float2 uv_LightMap = i.ase_texcoord1.xy * _LightMap_ST.xy + _LightMap_ST.zw;
				float4 tex2DNode43 = tex2D( _LightMap, uv_LightMap );
				float RampAdd57 = tex2DNode43.r;
				float2 uv_NormalMap = i.ase_texcoord1.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float4 tex2DNode4 = tex2D( _NormalMap, uv_NormalMap );
				float3 ase_worldTangent = i.ase_texcoord2.xyz;
				float3 ase_worldNormal = i.ase_texcoord3.xyz;
				float3 ase_worldBitangent = i.ase_texcoord4.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToWorldDir111 = mul( ase_tangentToWorldFast, tex2DNode4.rgb );
				float3 WorldNormalMap112 = tangentToWorldDir111;
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir(WorldPosition);
				float dotResult11 = dot( WorldNormalMap112 , worldSpaceLightDir );
				float ShaowAO48 = tex2DNode43.g;
				float4 lerpResult14 = lerp( DarkColor19 , BaseColor16 , ( step( ( RampAdd57 + _RampOffset ) , dotResult11 ) * ShaowAO48 ));
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult4_g3 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult98 = dot( normalizeResult4_g3 , ase_worldNormal );
				float SpecularMask60 = tex2DNode43.b;
				float Specular107 = ( ( pow( saturate( dotResult98 ) , _SpecularExp ) * _SpecularScale ) * SpecularMask60 );
				float4 Cloth24 = ( lerpResult14 + Specular107 );
				float dotResult115 = dot( ase_worldNormal , worldSpaceLightDir );
				float2 appendResult119 = (float2(( ( dotResult115 * 0.5 ) + 0.5 ) , 0.5));
				float4 lerpResult36 = lerp( DarkColor19 , BaseColor16 , tex2D( _SkinRamp, appendResult119 ));
				float4 Skin27 = lerpResult36;
				float4 lerpResult40 = lerp( DarkColor19 , BaseColor16 , tex2D( _FaceRamp, appendResult119 ));
				float2 uv_FaceLightMap = i.ase_texcoord1.xy * _FaceLightMap_ST.xy + _FaceLightMap_ST.zw;
				float4 Face41 = ( lerpResult40 + tex2D( _FaceLightMap, uv_FaceLightMap ).r );
				float2 uv_HairLightMap = i.ase_texcoord1.xy * _HairLightMap_ST.xy + _HairLightMap_ST.zw;
				float4 tex2DNode62 = tex2D( _HairLightMap, uv_HairLightMap );
				float3 normalizeResult4_g4 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult71 = dot( normalizeResult4_g4 , ase_worldNormal );
				float dotResult80 = dot( ase_worldNormal , worldSpaceLightDir );
				float4 lerpResult85 = lerp( DarkColor19 , BaseColor16 , step( ( tex2DNode62.g + _HairRampOffset ) , dotResult80 ));
				float4 Hair63 = ( ( tex2DNode62.r * ( pow( saturate( dotResult71 ) , _HairSpecularExponent ) * _HairSpecularScale ) ) + lerpResult85 );
				float4 temp_cast_1 = (i.ase_color.r).xxxx;
				float4 temp_cast_2 = (i.ase_color.g).xxxx;
				float4 temp_cast_3 = (i.ase_color.b).xxxx;
				float4 LightMap90 = tex2DNode43;
				float4 break92 = LightMap90;
				float4 temp_cast_4 = (break92.r).xxxx;
				float4 temp_cast_5 = (break92.g).xxxx;
				float4 temp_cast_6 = (break92.b).xxxx;
				float4 temp_cast_7 = (break92.a).xxxx;
				#if defined(_DEBUG_BASECOLOR)
				float4 staticSwitch1 = tex2DNode2;
				#elif defined(_DEBUG_NORMALMAP)
				float4 staticSwitch1 = tex2DNode4;
				#elif defined(_DEBUG_VC_R)
				float4 staticSwitch1 = temp_cast_1;
				#elif defined(_DEBUG_VC_G)
				float4 staticSwitch1 = temp_cast_2;
				#elif defined(_DEBUG_VC_B)
				float4 staticSwitch1 = temp_cast_3;
				#elif defined(_DEBUG_L_R)
				float4 staticSwitch1 = temp_cast_4;
				#elif defined(_DEBUG_L_G)
				float4 staticSwitch1 = temp_cast_5;
				#elif defined(_DEBUG_L_B)
				float4 staticSwitch1 = temp_cast_6;
				#elif defined(_DEBUG_L_A)
				float4 staticSwitch1 = temp_cast_7;
				#else
				float4 staticSwitch1 = tex2DNode2;
				#endif
				float4 Debug44 = staticSwitch1;
				#if defined(_TYPE_CLOTH)
				float4 staticSwitch23 = Cloth24;
				#elif defined(_TYPE_SKIN)
				float4 staticSwitch23 = Skin27;
				#elif defined(_TYPE_FACE)
				float4 staticSwitch23 = Face41;
				#elif defined(_TYPE_HAIR)
				float4 staticSwitch23 = Hair63;
				#elif defined(_TYPE_DEBUG)
				float4 staticSwitch23 = Debug44;
				#else
				float4 staticSwitch23 = Cloth24;
				#endif
				
				
				finalColor = staticSwitch23;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18800
-144.8;937.6;1645.6;795.8;156.1812;869.8591;1;True;False
Node;AmplifyShaderEditor.SamplerNode;4;-1845.048,455.5952;Inherit;True;Property;_NormalMap;NormalMap;3;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;9;-1244.247,-581.9819;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;114;-1264.49,-416.4141;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;43;691.787,-562.0507;Inherit;True;Property;_LightMap;LightMap;10;0;Create;True;0;0;0;False;0;False;-1;None;4611234591c855c4cbc1b59822e13a60;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;96;-1505.012,1290.902;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;94;1318.806,-742.7675;Inherit;False;274.8;165.4;RampAdd;1;57;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;97;-1550.012,1201.902;Inherit;False;Blinn-Phong Half Vector;-1;;3;91a149ac9d615be429126c95e20753ce;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;111;-1664.549,756.8848;Inherit;False;Tangent;World;False;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;115;-1035.489,-487.4142;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-1056.938,-345.9135;Inherit;False;Constant;_Float4;Float 4;7;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;98;-1305.012,1221.902;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;1368.806,-692.7675;Inherit;False;RampAdd;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;95;1316.094,-421.63;Inherit;False;274.8;165.4;SpecularMask ，GGX高光？;1;60;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;112;-1426.549,746.8848;Inherit;False;WorldNormalMap;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;104;-1127.97,1417.618;Inherit;False;Property;_SpecularScale;SpecularScale;16;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;93;1641.102,-597.2515;Inherit;False;274.8;165.4;ShadowAO;1;48;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;-895.9382,-458.9135;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-988.7114,340.5978;Inherit;False;Property;_DarkIntensity;DarkIntensity;6;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;-1510.549,-1080.115;Inherit;False;112;WorldNormalMap;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;2;-1338.805,227.2559;Inherit;True;Property;_MainTex;MainTex;2;0;Create;True;0;0;0;False;0;False;-1;None;8b70a40e3c430694d89a002d6f6ba7b4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;13;-1148.846,-1199.682;Inherit;False;Property;_RampOffset;RampOffset;4;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;58;-1037.019,-1309.339;Inherit;False;57;RampAdd;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-1124.97,1336.618;Inherit;False;Property;_SpecularExp;SpecularExp;15;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;101;-1139.011,1224.902;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;68;882.3332,994.0123;Inherit;False;Blinn-Phong Half Vector;-1;;4;91a149ac9d615be429126c95e20753ce;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;1366.094,-371.63;Inherit;False;SpecularMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;10;-1277.847,-977.6819;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;70;926.3332,1075.012;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;56;-1279.189,50.80588;Inherit;False;Property;_BrightIntensity;BrightIntensity;7;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;71;1125.334,993.0123;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;118;-751.9382,-415.9135;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;79;1077.502,1674.309;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;102;-876.0112,1225.902;Inherit;False;PowerScale;-1;;5;5ba70760a40e0a6499195a0590fd2e74;0;3;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;106;-881.3845,1402.368;Inherit;False;60;SpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;59;-830.0189,-1252.339;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-682.7114,240.5979;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;11;-1048.846,-1048.682;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;48;1696.102,-515.2515;Inherit;False;ShaowAO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;82;1154.504,1410.308;Inherit;False;Property;_HairRampOffset;HairRampOffset;5;0;Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;78;1108.502,1536.308;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;62;1134.716,771.342;Inherit;True;Property;_HairLightMap;HairLightMap;11;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;-913.1886,26.80597;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;16;-749.7114,50.59782;Inherit;False;BaseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;75;1279.334,993.0123;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-631.3846,1238.368;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;12;-591.8464,-1169.682;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;90;1048.706,-563.3018;Inherit;False;LightMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;73;1230.334,1173.012;Inherit;False;Property;_HairSpecularScale;HairSpecularScale;13;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;49;-629.3315,-1064.291;Inherit;False;48;ShaowAO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;72;1206.334,1088.012;Inherit;False;Property;_HairSpecularExponent;HairSpecularExponent;12;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;119;-563.9382,-404.9135;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;80;1313.504,1537.308;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;19;-520.7113,233.5979;Inherit;False;DarkColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;83;1557.331,1406.651;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;1705.563,1280.519;Inherit;False;16;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-453.1289,-1125.817;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;84;1694.503,1405.308;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;37;-313.5389,-466.6541;Inherit;True;Property;_FaceRamp;FaceRamp;9;0;Create;True;0;0;0;False;0;False;-1;None;e9484751079e3cd44bcf5ab0eb626c0f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;69;1589.334,992.0123;Inherit;False;PowerScale;-1;;6;5ba70760a40e0a6499195a0590fd2e74;0;3;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;20;-599.4478,-1263.133;Inherit;False;16;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;86;1710.156,1191.63;Inherit;False;19;DarkColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-1173.156,805.752;Inherit;False;90;LightMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;21;-601.4478,-1342.133;Inherit;False;19;DarkColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;107;-462.3844,1230.368;Inherit;False;Specular;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;-246.9764,-618.5782;Inherit;False;19;DarkColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;38;-244.9764,-540.5784;Inherit;False;16;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;108;-120.4385,-1179.092;Inherit;False;107;Specular;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;87;-311.4006,-261.4393;Inherit;True;Property;_FaceLightMap;FaceLightMap;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;14;-111.4036,-1309.282;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;40;7.336072,-606.8061;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;1816.334,923.0123;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;26;-307.3866,-863.8656;Inherit;True;Property;_SkinRamp;SkinRamp;8;0;Create;True;0;0;0;False;0;False;-1;None;4ed87fefdb8eb5b4ab9ae5d2f9bfbf7a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;34;-199.8265,-1032.925;Inherit;False;19;DarkColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;35;-197.8265,-954.9253;Inherit;False;16;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.BreakToComponentsNode;92;-1010.984,811.0533;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.LerpOp;85;1992.227,1257.066;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;3;-994.6172,559.5587;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;109;81.85485,-1316.045;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;36;54.48593,-1021.153;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;1;-631.8044,476.256;Inherit;False;Property;_Debug;Debug;1;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;9;BaseColor;NormalMap;VC_R;VC_G;VC_B;L_R;L_G;L_B;L_A;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;2088.15,983.2803;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;212.1359,-604.8573;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;2278.98,967.592;Inherit;False;Hair;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-370.0337,474.5668;Inherit;False;Debug;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;24;237.4089,-1318.629;Inherit;False;Cloth;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;251.4822,-1026.924;Inherit;False;Skin;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;41;341.4611,-610.6541;Inherit;False;Face;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;64;1009.222,-857.1541;Inherit;False;63;Hair;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;45;995.576,-746.1594;Inherit;False;44;Debug;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;1004.161,-953.9541;Inherit;False;41;Face;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;1004.443,-1052.696;Inherit;False;27;Skin;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;25;1004.553,-1151.767;Inherit;False;24;Cloth;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;54;-630.1166,846.3149;Inherit;False;310.8;165.4;脸部描边线条粗细;1;7;;1,1,1,1;0;0
Node;AmplifyShaderEditor.StepOpNode;52;1509.297,-545.3391;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;1254.331,1274.651;Inherit;False;57;RampAdd;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-190.527,896.1535;Inherit;False;7;FaceOutlineIntensity;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;51;-926.6116,459.5107;Inherit;False;Constant;_Float2;Float 2;9;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-794.8756,-965.1051;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;22;-117.7629,166.4568;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;30;-955.8756,-852.1051;Inherit;False;Constant;_Float0;Float 0;7;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;23;1561.548,-1053.74;Inherit;False;Property;_Type;Type;0;0;Create;True;0;0;0;False;0;False;0;0;1;True;;KeywordEnum;5;Cloth;Skin;Face;Hair;Debug;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;31;-650.8756,-922.1051;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-613.9163,892.4149;Inherit;False;FaceOutlineIntensity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;32;-462.8756,-911.1051;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;53;1319.297,-550.3391;Inherit;False;Constant;_Float3;Float 3;9;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1808.133,-1051.123;Float;False;True;-1;2;ASEMaterialInspector;100;1;NPR_ZS_Body;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;111;0;4;0
WireConnection;115;0;9;0
WireConnection;115;1;114;0
WireConnection;98;0;97;0
WireConnection;98;1;96;0
WireConnection;57;0;43;1
WireConnection;112;0;111;0
WireConnection;117;0;115;0
WireConnection;117;1;116;0
WireConnection;101;0;98;0
WireConnection;60;0;43;3
WireConnection;71;0;68;0
WireConnection;71;1;70;0
WireConnection;118;0;117;0
WireConnection;118;1;116;0
WireConnection;102;1;101;0
WireConnection;102;2;103;0
WireConnection;102;3;104;0
WireConnection;59;0;58;0
WireConnection;59;1;13;0
WireConnection;17;0;2;0
WireConnection;17;1;18;0
WireConnection;11;0;113;0
WireConnection;11;1;10;0
WireConnection;48;0;43;2
WireConnection;55;0;2;0
WireConnection;55;1;56;0
WireConnection;16;0;55;0
WireConnection;75;0;71;0
WireConnection;105;0;102;0
WireConnection;105;1;106;0
WireConnection;12;0;59;0
WireConnection;12;1;11;0
WireConnection;90;0;43;0
WireConnection;119;0;118;0
WireConnection;119;1;116;0
WireConnection;80;0;78;0
WireConnection;80;1;79;0
WireConnection;19;0;17;0
WireConnection;83;0;62;2
WireConnection;83;1;82;0
WireConnection;50;0;12;0
WireConnection;50;1;49;0
WireConnection;84;0;83;0
WireConnection;84;1;80;0
WireConnection;37;1;119;0
WireConnection;69;1;75;0
WireConnection;69;2;72;0
WireConnection;69;3;73;0
WireConnection;107;0;105;0
WireConnection;14;0;21;0
WireConnection;14;1;20;0
WireConnection;14;2;50;0
WireConnection;40;0;39;0
WireConnection;40;1;38;0
WireConnection;40;2;37;0
WireConnection;74;0;62;1
WireConnection;74;1;69;0
WireConnection;26;1;119;0
WireConnection;92;0;91;0
WireConnection;85;0;86;0
WireConnection;85;1;76;0
WireConnection;85;2;84;0
WireConnection;109;0;14;0
WireConnection;109;1;108;0
WireConnection;36;0;34;0
WireConnection;36;1;35;0
WireConnection;36;2;26;0
WireConnection;1;1;2;0
WireConnection;1;0;4;0
WireConnection;1;2;3;1
WireConnection;1;3;3;2
WireConnection;1;4;3;3
WireConnection;1;5;92;0
WireConnection;1;6;92;1
WireConnection;1;7;92;2
WireConnection;1;8;92;3
WireConnection;77;0;74;0
WireConnection;77;1;85;0
WireConnection;88;0;40;0
WireConnection;88;1;87;1
WireConnection;63;0;77;0
WireConnection;44;0;1;0
WireConnection;24;0;109;0
WireConnection;27;0;36;0
WireConnection;41;0;88;0
WireConnection;52;0;53;0
WireConnection;52;1;43;2
WireConnection;29;0;11;0
WireConnection;29;1;30;0
WireConnection;23;1;25;0
WireConnection;23;0;28;0
WireConnection;23;2;42;0
WireConnection;23;3;64;0
WireConnection;23;4;45;0
WireConnection;31;0;29;0
WireConnection;31;1;30;0
WireConnection;7;0;3;3
WireConnection;32;0;31;0
WireConnection;32;1;30;0
WireConnection;0;0;23;0
ASEEND*/
//CHKSM=8134E7FBEE835726FEB7EC651E79A309315F0D5D