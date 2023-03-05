// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GGX_Body_ASE"
{
	Properties
	{
		[KeywordEnum(None,DebugMode,VertexColor,Face)] _Usage("Usage", Float) = 0
		[KeywordEnum(BaseColor,Shadow,LM_R,LM_G,LM_B,LM_A,NormalLocal,Decal,Specular)] _Debug("Debug", Float) = 0
		[HDR]_Tone("Tone", Color) = (0,0,0,0)
		_BaseMap("BaseMap", 2D) = "white" {}
		_MaskMap("MaskMap", 2D) = "white" {}
		_TintMap("TintMap", 2D) = "white" {}
		_Decal("Decal", 2D) = "white" {}
		_Threshold("Threshold", Range( -1 , 1)) = 0
		_ShadowStep("ShadowStep", Float) = 0.1
		_NVScale("NVScale", Range( 0 , 1)) = 0.1
		_SpecularExp("SpecularExp", Float) = 0
		_SpecularExpScale("SpecularExpScale", Float) = 0
		_SpecularExpStepValue("SpecularExpStepValue", Float) = 1
		_SpecularIntensity("SpecularIntensity", Float) = 0
		_FaceStepThreshold("FaceStepThreshold", Range( -1 , 1)) = 0
		_RimLightExp("RimLightExp", Float) = 4
		_RimLightStep("RimLightStep", Float) = 0
		_RimLightScale("RimLightScale", Float) = 1
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
		
		
		UsePass "NPR/OutLine/COLOR"

		Pass
		{
			Name "Unlit"
			Tags {  }
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
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_NORMAL
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _USAGE_NONE _USAGE_DEBUGMODE _USAGE_VERTEXCOLOR _USAGE_FACE
			#pragma shader_feature_local _DEBUG_BASECOLOR _DEBUG_SHADOW _DEBUG_LM_R _DEBUG_LM_G _DEBUG_LM_B _DEBUG_LM_A _DEBUG_NORMALLOCAL _DEBUG_DECAL _DEBUG_SPECULAR


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
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
				float3 ase_normal : NORMAL;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform sampler2D _TintMap;
			uniform float4 _TintMap_ST;
			uniform sampler2D _BaseMap;
			uniform float4 _BaseMap_ST;
			uniform float _FaceStepThreshold;
			uniform float _ShadowStep;
			uniform sampler2D _MaskMap;
			uniform float4 _MaskMap_ST;
			uniform float _Threshold;
			uniform float _NVScale;
			uniform float _SpecularExpStepValue;
			uniform float _SpecularExp;
			uniform float _SpecularExpScale;
			uniform float _SpecularIntensity;
			uniform float _RimLightStep;
			uniform float _RimLightExp;
			uniform float _RimLightScale;
			uniform float4 _Tone;
			uniform sampler2D _Decal;
			uniform float4 _Decal_ST;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 objectSpaceLightDir = ObjSpaceLightDir(v.vertex);
				o.ase_texcoord2.xyz = objectSpaceLightDir;
				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord3.xyz = ase_worldNormal;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_normal = v.ase_normal;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
				o.ase_texcoord3.w = 0;
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
				float2 uv_TintMap = i.ase_texcoord1.xy * _TintMap_ST.xy + _TintMap_ST.zw;
				float4 tex2DNode3 = tex2D( _TintMap, uv_TintMap );
				float4 ShadowMap10 = tex2DNode3;
				float2 uv_BaseMap = i.ase_texcoord1.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode1 = tex2D( _BaseMap, uv_BaseMap );
				float4 BaseColor9 = tex2DNode1;
				float3 objectSpaceLightDir = i.ase_texcoord2.xyz;
				float dotResult116 = dot( float3(0,0,1) , objectSpaceLightDir );
				float temp_output_119_0 = step( 0.0 , dotResult116 );
				float3 lerpResult122 = lerp( float3(0,0,-1) , float3(0,0,1) , temp_output_119_0);
				float dotResult96 = dot( i.ase_normal , lerpResult122 );
				float4 lerpResult114 = lerp( ( ShadowMap10 * BaseColor9 ) , BaseColor9 , ( step( _FaceStepThreshold , dotResult96 ) * temp_output_119_0 ));
				float4 Face99 = lerpResult114;
				float2 uv_MaskMap = i.ase_texcoord1.xy * _MaskMap_ST.xy + _MaskMap_ST.zw;
				float4 tex2DNode2 = tex2D( _MaskMap, uv_MaskMap );
				float4 LightMap11 = tex2DNode2;
				float4 break30 = LightMap11;
				float ShadowMask38 = break30.g;
				float RampOffset37 = break30.r;
				float3 worldSpaceLightDir = UnityWorldSpaceLightDir(WorldPosition);
				float3 ase_worldNormal = i.ase_texcoord3.xyz;
				float dotResult21 = dot( worldSpaceLightDir , ase_worldNormal );
				float NL49 = dotResult21;
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float dotResult51 = dot( ase_worldViewDir , ase_worldNormal );
				float NV54 = dotResult51;
				float4 lerpResult43 = lerp( ( ShadowMap10 * BaseColor9 ) , BaseColor9 , ( step( _ShadowStep , ShadowMask38 ) * step( ( _Threshold + RampOffset37 ) , ( NL49 + ( NV54 * _NVScale ) ) ) ));
				float3 normalizeResult4_g3 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult68 = dot( ase_worldNormal , normalizeResult4_g3 );
				float SpecularMask39 = break30.b;
				float Specular75 = ( step( _SpecularExpStepValue , ( ( pow( saturate( dotResult68 ) , _SpecularExp ) * _SpecularExpScale ) * SpecularMask39 ) ) * _SpecularIntensity );
				float InnerLine40 = break30.a;
				float FaceMask101 = tex2DNode1.a;
				float4 lerpResult102 = lerp( Face99 , ( ( lerpResult43 + Specular75 ) * InnerLine40 ) , FaceMask101);
				float4 temp_cast_0 = (1.0).xxxx;
				float3 objToWorldDir141 = mul( unity_ObjectToWorld, float4( ( ( i.ase_color * 2.0 ) - temp_cast_0 ).rgb, 0 ) ).xyz;
				float dotResult143 = dot( objToWorldDir141 , ase_worldViewDir );
				float RimLight133 = ( step( _RimLightStep , pow( ( 1.0 - dotResult143 ) , _RimLightExp ) ) * _RimLightScale );
				float4 Final28 = ( ( lerpResult102 + RimLight133 ) * _Tone );
				float4 temp_cast_2 = (tex2DNode2.r).xxxx;
				float4 temp_cast_3 = (tex2DNode2.g).xxxx;
				float4 temp_cast_4 = (tex2DNode2.b).xxxx;
				float4 temp_cast_5 = (tex2DNode2.a).xxxx;
				float2 uv_Decal = i.ase_texcoord1.xy * _Decal_ST.xy + _Decal_ST.zw;
				float4 temp_cast_7 = (Specular75).xxxx;
				#if defined(_DEBUG_BASECOLOR)
				float4 staticSwitch5 = tex2DNode1;
				#elif defined(_DEBUG_SHADOW)
				float4 staticSwitch5 = ( tex2DNode1 * tex2DNode3 );
				#elif defined(_DEBUG_LM_R)
				float4 staticSwitch5 = temp_cast_2;
				#elif defined(_DEBUG_LM_G)
				float4 staticSwitch5 = temp_cast_3;
				#elif defined(_DEBUG_LM_B)
				float4 staticSwitch5 = temp_cast_4;
				#elif defined(_DEBUG_LM_A)
				float4 staticSwitch5 = temp_cast_5;
				#elif defined(_DEBUG_NORMALLOCAL)
				float4 staticSwitch5 = float4( i.ase_normal , 0.0 );
				#elif defined(_DEBUG_DECAL)
				float4 staticSwitch5 = tex2D( _Decal, uv_Decal );
				#elif defined(_DEBUG_SPECULAR)
				float4 staticSwitch5 = temp_cast_7;
				#else
				float4 staticSwitch5 = tex2DNode1;
				#endif
				#if defined(_USAGE_NONE)
				float4 staticSwitch27 = Final28;
				#elif defined(_USAGE_DEBUGMODE)
				float4 staticSwitch27 = staticSwitch5;
				#elif defined(_USAGE_VERTEXCOLOR)
				float4 staticSwitch27 = i.ase_color;
				#elif defined(_USAGE_FACE)
				float4 staticSwitch27 = Face99;
				#else
				float4 staticSwitch27 = Final28;
				#endif
				
				
				finalColor = staticSwitch27;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18800
84.8;173.6;1734.4;917.4;-296.266;-2873.058;1;True;False
Node;AmplifyShaderEditor.SamplerNode;2;-665,221.7;Inherit;True;Property;_MaskMap;MaskMap;4;0;Create;True;0;0;0;False;0;False;-1;6d1c10fc03e1b0344b8a78a5fc5aa25e;6d1c10fc03e1b0344b8a78a5fc5aa25e;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;11;-271.8567,174.3762;Inherit;False;LightMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;67;718.0353,2211.606;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;66;628.8782,2391.257;Inherit;False;Blinn-Phong Half Vector;-1;;3;91a149ac9d615be429126c95e20753ce;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;15;-1226.099,894.4724;Inherit;False;11;LightMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WorldNormalVector;52;-1109.58,1991.728;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;53;-1109.247,1831.728;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;138;842.0584,3437.126;Inherit;False;Constant;_Float0;Float 0;18;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;94;-1632,3008;Inherit;False;Constant;_Vector0;Vector 0;14;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.BreakToComponentsNode;30;-1055.188,899.1555;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.CommentaryNode;117;-1392,3040;Inherit;False;202.4;183.8;1:光线在前，0光线在后;1;116;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;68;1024.878,2299.257;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;51;-762.5807,1904.728;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;135;825.0585,3277.126;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjSpaceLightDirHlpNode;115;-1696,3152;Inherit;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;20;-972.928,1535.265;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;19;-997.928,1361.265;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;140;1017.059,3363.126;Inherit;False;Constant;_Float1;Float 1;18;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;136;1020.059,3279.126;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;73;1078.622,2552.766;Inherit;False;Property;_SpecularExpScale;SpecularExpScale;11;0;Create;True;0;0;0;False;0;False;0;16;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;21;-625.9282,1448.265;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;72;1075.622,2435.767;Inherit;False;Property;_SpecularExp;SpecularExp;10;0;Create;True;0;0;0;False;0;False;0;7.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;70;1159.622,2304.767;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-866.4832,991.0413;Inherit;False;SpecularMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-625.2472,1885.728;Inherit;False;NV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;116;-1344,3088;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;119;-1152,3072;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;121;-1344,2736;Inherit;False;Constant;_Vector2;Vector 2;14;0;Create;True;0;0;0;False;0;False;0,0,-1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;77;1449.029,2578.171;Inherit;False;39;SpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;71;1491.622,2383.767;Inherit;False;PowerScale;-1;;4;5ba70760a40e0a6499195a0590fd2e74;0;3;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;58;-368.2472,1554.728;Inherit;False;54;NV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;60;-450.044,1638.395;Inherit;False;Property;_NVScale;NVScale;9;0;Create;True;0;0;0;False;0;False;0.1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;120;-1344,2896;Inherit;False;Constant;_Vector1;Vector 1;14;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;37;-868.0703,807.653;Inherit;False;RampOffset;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;49;-509.5551,1438.344;Inherit;False;NL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;139;1173.06,3278.126;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;122;-1104,2768;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;141;1319.06,3275.126;Inherit;False;Object;World;False;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;78;1751.029,2436.171;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;147;1362.152,3425.223;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;1;-672,-170.3;Inherit;True;Property;_BaseMap;BaseMap;3;0;Create;True;0;0;0;False;0;False;-1;8b085225b0d188240acc40e0aa152fe1;8b085225b0d188240acc40e0aa152fe1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;3;-670,34.69998;Inherit;True;Property;_TintMap;TintMap;5;0;Create;True;0;0;0;False;0;False;-1;7a0d04bb4a942764e884428417fd22ae;7a0d04bb4a942764e884428417fd22ae;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-152.2472,1547.728;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;38;-865.8959,904.1548;Inherit;False;ShadowMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;123;-1120,2624;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;55;-236.2472,1390.728;Inherit;False;49;NL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-645.0723,1331.766;Inherit;False;37;RampOffset;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;1397.095,2712.012;Inherit;False;Property;_SpecularExpStepValue;SpecularExpStepValue;12;0;Create;True;0;0;0;False;0;False;1;1.06;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-660.8547,1232.4;Inherit;False;Property;_Threshold;Threshold;7;0;Create;True;0;0;0;False;0;False;0;0.46;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;56;-6.247192,1419.728;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;9;-303.8567,-214.6238;Inherit;False;BaseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;96;-880,2608;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;107;-1040,2528;Inherit;False;Property;_FaceStepThreshold;FaceStepThreshold;14;0;Create;True;0;0;0;False;0;False;0;0.52;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;90;1934.095,2525.012;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;89;1451.095,2888.012;Inherit;False;Property;_SpecularIntensity;SpecularIntensity;13;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;45;-128.0272,1196.75;Inherit;False;38;ShadowMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;32;-321.6411,1274.433;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-124.0272,1103.75;Inherit;False;Property;_ShadowStep;ShadowStep;8;0;Create;True;0;0;0;False;0;False;0.1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;10;-301.8567,17.37616;Inherit;False;ShadowMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;143;1708.152,3278.223;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;126;1824.576,3280.952;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;128;1799.576,3369.952;Inherit;False;Property;_RimLightExp;RimLightExp;15;0;Create;True;0;0;0;False;0;False;4;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;111;-768,2432;Inherit;False;9;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;106;-736,2544;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;2141.095,2637.012;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-768,2336;Inherit;False;10;ShadowMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;16;149.8263,860.3781;Inherit;False;10;ShadowMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;14;149.8263,946.378;Inherit;False;9;BaseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;46;97.97278,1136.75;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;25;205.8162,1260;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;132;1971.576,3190.952;Inherit;False;Property;_RimLightStep;RimLightStep;16;0;Create;True;0;0;0;False;0;False;0;0.23;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;127;1982.576,3268.952;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;75;2326.96,2620.024;Inherit;False;Specular;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;118;-576,2544;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;113;-528,2336;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;428.9728,1228.75;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;382.3856,868.4681;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;640.6081,1251.945;Inherit;False;75;Specular;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;114;-148.0287,2396.868;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;43;674.2322,1044.625;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-865.0723,1084.766;Inherit;False;InnerLine;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;131;2128.576,3342.952;Inherit;False;Property;_RimLightScale;RimLightScale;17;0;Create;True;0;0;0;False;0;False;1;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;129;2167.576,3250.952;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;130;2333.576,3254.952;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;74;969.7507,1135.937;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;924.8959,1299.677;Inherit;False;40;InnerLine;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;101;-299.5632,-106.3303;Inherit;False;FaceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;99;327.3143,2439.6;Inherit;False;Face;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;133;2469.576,3249.952;Inherit;False;RimLight;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;100;967.333,1408.195;Inherit;False;99;Face;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;105;948.9274,1539.9;Inherit;False;101;FaceMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;1128.448,1182.945;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;102;1357.591,1274.89;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;142;1401.001,1464.924;Inherit;False;133;RimLight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;83;1573.708,1498.556;Inherit;False;Property;_Tone;Tone;2;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;1.319508,1.122901,1.122901,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;134;1571.179,1308.815;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;1893.116,1339.723;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;24;-570.1147,417.8678;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;4;-652.3756,608.0171;Inherit;True;Property;_Decal;Decal;6;0;Create;True;0;0;0;False;0;False;-1;b1c28fa310c921f4c83b622f152d3087;b1c28fa310c921f4c83b622f152d3087;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;-45.18323,167.4323;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;28;2107.889,1340.077;Inherit;False;Final;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;18.82837,487.0776;Inherit;False;75;Specular;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;84;311.5372,492.0913;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;108;505.0168,692.1727;Inherit;False;99;Face;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;5;222.8711,180.9005;Inherit;False;Property;_Debug;Debug;1;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;9;BaseColor;Shadow;LM_R;LM_G;LM_B;LM_A;NormalLocal;Decal;Specular;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;29;303.1573,69.55006;Inherit;False;28;Final;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;162;-571.4034,3566.841;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StickyNoteNode;23;-1148.159,65.09512;Inherit;False;371;192;New Note;;1,1,1,1;LightMap.R : StepOffset$LightMap.G : 阴影Mask$LightMap.B : 高光强度$LightMap.A : 内购线;0;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;160;-1051.901,3571.793;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;154;319.5512,2590.007;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;162.5512,2547.007;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;27;627.6734,298.4936;Inherit;False;Property;_Usage;Usage;0;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;4;None;DebugMode;VertexColor;Face;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;168;-34.15063,3133.451;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;149;-358.3411,2714.762;Inherit;True;Property;_FaceMaskNose;FaceMaskNose;18;0;Create;True;0;0;0;False;0;False;-1;13a956fcc42d59f4ab03e82d7330b985;13a956fcc42d59f4ab03e82d7330b985;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;152;-464.2864,2945.909;Inherit;False;Property;_NoiseTriangleLightScale;NoiseTriangleLightScale;19;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;166;-465.1506,3052.451;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;163;-415.1506,3251.451;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;165;-743.1506,3202.451;Inherit;False;Constant;_Vector4;Vector 4;20;0;Create;True;0;0;0;False;0;False;-1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;167;-215.1506,3134.451;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;161;-800.9008,3568.793;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StickyNoteNode;124;-2176,2336;Inherit;False;371;192;New Note;;1,1,1,1;GGXxrd中每一帧都调节灯光方向，以解决灯光问题;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;153;35.55121,2772.007;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;169;780.2197,119.6891;Inherit;False;Constant;_Float2;Float 2;20;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;164;-701.1506,3349.451;Inherit;False;Constant;_Vector3;Vector 3;20;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1073.956,256.1987;Float;False;True;-1;2;ASEMaterialInspector;100;1;GGX_Body_ASE;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;1;Above;NPR/OutLine/COLOR;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;11;0;2;0
WireConnection;30;0;15;0
WireConnection;68;0;67;0
WireConnection;68;1;66;0
WireConnection;51;0;53;0
WireConnection;51;1;52;0
WireConnection;136;0;135;0
WireConnection;136;1;138;0
WireConnection;21;0;19;0
WireConnection;21;1;20;0
WireConnection;70;0;68;0
WireConnection;39;0;30;2
WireConnection;54;0;51;0
WireConnection;116;0;94;0
WireConnection;116;1;115;0
WireConnection;119;1;116;0
WireConnection;71;1;70;0
WireConnection;71;2;72;0
WireConnection;71;3;73;0
WireConnection;37;0;30;0
WireConnection;49;0;21;0
WireConnection;139;0;136;0
WireConnection;139;1;140;0
WireConnection;122;0;121;0
WireConnection;122;1;120;0
WireConnection;122;2;119;0
WireConnection;141;0;139;0
WireConnection;78;0;71;0
WireConnection;78;1;77;0
WireConnection;59;0;58;0
WireConnection;59;1;60;0
WireConnection;38;0;30;1
WireConnection;56;0;55;0
WireConnection;56;1;59;0
WireConnection;9;0;1;0
WireConnection;96;0;123;0
WireConnection;96;1;122;0
WireConnection;90;0;88;0
WireConnection;90;1;78;0
WireConnection;32;0;31;0
WireConnection;32;1;41;0
WireConnection;10;0;3;0
WireConnection;143;0;141;0
WireConnection;143;1;147;0
WireConnection;126;0;143;0
WireConnection;106;0;107;0
WireConnection;106;1;96;0
WireConnection;91;0;90;0
WireConnection;91;1;89;0
WireConnection;46;0;47;0
WireConnection;46;1;45;0
WireConnection;25;0;32;0
WireConnection;25;1;56;0
WireConnection;127;0;126;0
WireConnection;127;1;128;0
WireConnection;75;0;91;0
WireConnection;118;0;106;0
WireConnection;118;1;119;0
WireConnection;113;0;112;0
WireConnection;113;1;111;0
WireConnection;44;0;46;0
WireConnection;44;1;25;0
WireConnection;48;0;16;0
WireConnection;48;1;14;0
WireConnection;114;0;113;0
WireConnection;114;1;111;0
WireConnection;114;2;118;0
WireConnection;43;0;48;0
WireConnection;43;1;14;0
WireConnection;43;2;44;0
WireConnection;40;0;30;3
WireConnection;129;0;132;0
WireConnection;129;1;127;0
WireConnection;130;0;129;0
WireConnection;130;1;131;0
WireConnection;74;0;43;0
WireConnection;74;1;76;0
WireConnection;101;0;1;4
WireConnection;99;0;114;0
WireConnection;133;0;130;0
WireConnection;82;0;74;0
WireConnection;82;1;81;0
WireConnection;102;0;100;0
WireConnection;102;1;82;0
WireConnection;102;2;105;0
WireConnection;134;0;102;0
WireConnection;134;1;142;0
WireConnection;62;0;134;0
WireConnection;62;1;83;0
WireConnection;110;0;1;0
WireConnection;110;1;3;0
WireConnection;28;0;62;0
WireConnection;5;1;1;0
WireConnection;5;0;110;0
WireConnection;5;2;2;1
WireConnection;5;3;2;2
WireConnection;5;4;2;3
WireConnection;5;5;2;4
WireConnection;5;6;24;0
WireConnection;5;7;4;0
WireConnection;5;8;79;0
WireConnection;162;0;161;1
WireConnection;155;0;114;0
WireConnection;155;1;153;0
WireConnection;27;1;29;0
WireConnection;27;0;5;0
WireConnection;27;2;84;0
WireConnection;27;3;108;0
WireConnection;168;0;167;0
WireConnection;163;0;165;0
WireConnection;163;1;164;0
WireConnection;163;2;162;0
WireConnection;167;0;166;0
WireConnection;167;1;163;0
WireConnection;161;0;160;0
WireConnection;153;0;149;1
WireConnection;153;1;168;0
WireConnection;153;2;152;0
WireConnection;0;0;27;0
ASEEND*/
//CHKSM=C6355A49ADF9987B1EA6D58CE8867DA5D49584D9