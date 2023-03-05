// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "NPR/NPR_GBVS_ASE"
{
	Properties
	{
		[KeywordEnum(None,Base,Base_A,Shadow,Debug2,Debug3,Specular,AddLight)] _Debug("Debug", Float) = 0
		[KeywordEnum(Mask_R,Mask_G,Mask_B,Mask_A,VC_R,VC_G,VC_B,VC_A)] _Debug2("Debug2", Float) = 0
		[KeywordEnum(Normal,Tangent)] _Debug3("Debug3", Float) = 0
		_BaseMap("BaseMap", 2D) = "white" {}
		_ShadowMap("ShadowMap", 2D) = "white" {}
		_MaskMap("MaskMap", 2D) = "white" {}
		_Threshold("Threshold", Range( -1 , 1)) = 0
		_ThresholdSecond("ThresholdSecond", Range( -1 , 1)) = 0
		_Decal("Decal", 2D) = "white" {}
		_DecalLerp("DecalLerp", Range( 0 , 1)) = 0
		_SpecularExp("SpecularExp", Float) = 4
		_SpecularIntensity("SpecularIntensity", Float) = 4
		_SpecularScale("SpecularScale", Float) = 1
		_SpucularStep("SpucularStep", Float) = 0
		_BrightDarkLerp("BrightDarkLerp", Range( 0 , 1)) = 0
		_Cloth1_StepExp("Cloth1_StepExp", Float) = 1
		_Cloth1_StepScale("Cloth1_StepScale", Float) = 1
		_Cloth1_StepIntensity("Cloth1_StepIntensity", Float) = 1
		_Cloth1_RimeStepValue("Cloth1_RimeStepValue", Float) = 1
		_Cloth2_StepExp("Cloth2_StepExp", Float) = 1
		_Cloth2_StepScale("Cloth2_StepScale", Float) = 1
		_Cloth2_StepIntensity("Cloth2_StepIntensity", Float) = 1
		_Cloth2_RimeStepValue("Cloth2_RimeStepValue", Float) = 1
		_MetallicViewLight_Exp("MetallicViewLight_Exp", Float) = 1
		_MetallicViewLight_Scale("MetallicViewLight_Scale", Float) = 1
		_MetallicViewLight_StepValue("MetallicViewLight_StepValue", Float) = 0.5
		_MetallicViewLight_Intensity("MetallicViewLight_Intensity", Float) = 1
		_PiZiRim_StepExp("PiZiRim_StepExp", Float) = 1
		_PiZiRim_StepScale("PiZiRim_StepScale", Float) = 1
		_PiZiRim_StepIntensity("PiZiRim_StepIntensity", Float) = 1
		_PiZiRim_RimeStepValue("PiZiRim_RimeStepValue", Float) = 1
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
		
		
		UsePass "NPR/OutLine/NORMAL"

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
			#include "UnityStandardBRDF.cginc"
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_COLOR
			#define ASE_NEEDS_FRAG_NORMAL
			#pragma shader_feature_local _DEBUG_NONE _DEBUG_BASE _DEBUG_BASE_A _DEBUG_SHADOW _DEBUG_DEBUG2 _DEBUG_DEBUG3 _DEBUG_SPECULAR _DEBUG_ADDLIGHT
			#pragma shader_feature_local _DEBUG2_MASK_R _DEBUG2_MASK_G _DEBUG2_MASK_B _DEBUG2_MASK_A _DEBUG2_VC_R _DEBUG2_VC_G _DEBUG2_VC_B _DEBUG2_VC_A
			#pragma shader_feature_local _DEBUG3_NORMAL _DEBUG3_TANGENT


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
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
				float4 ase_color : COLOR;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			//This is a late directive
			
			uniform sampler2D _ShadowMap;
			uniform float4 _ShadowMap_ST;
			uniform sampler2D _BaseMap;
			uniform float4 _BaseMap_ST;
			uniform float _Threshold;
			uniform sampler2D _MaskMap;
			uniform float4 _MaskMap_ST;
			uniform float _BrightDarkLerp;
			uniform float _ThresholdSecond;
			uniform float _SpucularStep;
			uniform float _SpecularExp;
			uniform float _SpecularScale;
			uniform float _SpecularIntensity;
			uniform float _Cloth1_RimeStepValue;
			uniform float _Cloth1_StepExp;
			uniform float _Cloth1_StepScale;
			uniform float _Cloth1_StepIntensity;
			uniform float _Cloth2_RimeStepValue;
			uniform float _Cloth2_StepExp;
			uniform float _Cloth2_StepScale;
			uniform float _Cloth2_StepIntensity;
			uniform float _PiZiRim_RimeStepValue;
			uniform float _PiZiRim_StepExp;
			uniform float _PiZiRim_StepScale;
			uniform float _PiZiRim_StepIntensity;
			uniform float _MetallicViewLight_StepValue;
			uniform float _MetallicViewLight_Exp;
			uniform float _MetallicViewLight_Scale;
			uniform float _MetallicViewLight_Intensity;
			uniform sampler2D _Decal;
			uniform float4 _Decal_ST;
			uniform float _DecalLerp;
			float MyCustomExpression167( float value )
			{
				return(value<0.3);
			}
			
			float MyCustomExpression168( float value )
			{
				return (value>0.3 && value<0.5);
			}
			
			float MyCustomExpression171( float value )
			{
				return(value>0.7);
			}
			
			float MyCustomExpression170( float value )
			{
				return(value>0.64 && value<0.7);
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float3 ase_worldNormal = UnityObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord2.xyz = ase_worldNormal;
				
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				o.ase_texcoord2.w = 0;
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
				float2 uv_ShadowMap = i.ase_texcoord1.xy * _ShadowMap_ST.xy + _ShadowMap_ST.zw;
				float4 tex2DNode16 = tex2D( _ShadowMap, uv_ShadowMap );
				float4 Shadow36 = tex2DNode16;
				float2 uv_BaseMap = i.ase_texcoord1.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
				float4 tex2DNode2 = tex2D( _BaseMap, uv_BaseMap );
				float4 Base34 = tex2DNode2;
				float2 uv_MaskMap = i.ase_texcoord1.xy * _MaskMap_ST.xy + _MaskMap_ST.zw;
				float4 tex2DNode22 = tex2D( _MaskMap, uv_MaskMap );
				float4 MaskMap54 = tex2DNode22;
				float4 break61 = MaskMap54;
				float RampOffset60 = break61.r;
				float3 worldSpaceLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(WorldPosition));
				float3 ase_worldNormal = i.ase_texcoord2.xyz;
				float dotResult28 = dot( worldSpaceLightDir , ase_worldNormal );
				float NL31 = dotResult28;
				float AO115 = i.ase_color.b;
				float MetallicAddLightMask57 = step( 0.2 , break61.g );
				float lerpResult124 = lerp( AO115 , ( MetallicAddLightMask57 * AO115 ) , _BrightDarkLerp);
				float temp_output_119_0 = ( step( ( _Threshold + RampOffset60 ) , NL31 ) * lerpResult124 );
				float4 lerpResult42 = lerp( Shadow36 , Base34 , temp_output_119_0);
				float4 lerpResult103 = lerp( Base34 , Shadow36 , 0.5);
				float4 Gray104 = lerpResult103;
				float temp_output_136_0 = ( step( ( _ThresholdSecond + RampOffset60 ) , NL31 ) * lerpResult124 );
				float4 lerpResult139 = lerp( Shadow36 , Gray104 , temp_output_136_0);
				float4 lerpResult141 = lerp( lerpResult42 , lerpResult139 , ( temp_output_136_0 - temp_output_119_0 ));
				float3 ase_worldViewDir = UnityWorldSpaceViewDir(WorldPosition);
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult4_g31 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult83 = dot( ase_worldNormal , normalizeResult4_g31 );
				float SpecularMask58 = break61.b;
				float Specular86 = ( ( step( _SpucularStep , ( pow( saturate( dotResult83 ) , _SpecularExp ) * _SpecularScale ) ) * _SpecularIntensity ) * SpecularMask58 );
				float Layer35 = tex2DNode2.a;
				float value167 = Layer35;
				float localMyCustomExpression167 = MyCustomExpression167( value167 );
				float Cloth1157 = localMyCustomExpression167;
				float dotResult3_g60 = dot( ase_worldNormal , ase_worldViewDir );
				float ClothRim1194 = ( step( _Cloth1_RimeStepValue , ( pow( ( 1.0 - dotResult3_g60 ) , _Cloth1_StepExp ) * _Cloth1_StepScale ) ) * _Cloth1_StepIntensity );
				float value168 = Layer35;
				float localMyCustomExpression168 = MyCustomExpression168( value168 );
				float Cloth2172 = localMyCustomExpression168;
				float dotResult3_g58 = dot( ase_worldNormal , ase_worldViewDir );
				float ClothRim2200 = ( step( _Cloth2_RimeStepValue , ( pow( ( 1.0 - dotResult3_g58 ) , _Cloth2_StepExp ) * _Cloth2_StepScale ) ) * _Cloth2_StepIntensity );
				float value171 = Layer35;
				float localMyCustomExpression171 = MyCustomExpression171( value171 );
				float Pizi175 = localMyCustomExpression171;
				float dotResult3_g62 = dot( ase_worldNormal , ase_worldViewDir );
				float PiZiRim213 = ( step( _PiZiRim_RimeStepValue , ( pow( ( 1.0 - dotResult3_g62 ) , _PiZiRim_StepExp ) * _PiZiRim_StepScale ) ) * _PiZiRim_StepIntensity );
				float value170 = Layer35;
				float localMyCustomExpression170 = MyCustomExpression170( value170 );
				float Metallic174 = localMyCustomExpression170;
				float3 normalizedWorldNormal = normalize( ase_worldNormal );
				float3 normalizeResult258 = normalize( ( ase_worldViewDir + worldSpaceLightDir ) );
				float dotResult204 = dot( normalizedWorldNormal , normalizeResult258 );
				float MetallicViewLight212 = ( step( _MetallicViewLight_StepValue , ( pow( dotResult204 , _MetallicViewLight_Exp ) * _MetallicViewLight_Scale ) ) * _MetallicViewLight_Intensity * SpecularMask58 );
				float lerpResult249 = lerp( ( Metallic174 * MetallicViewLight212 ) , 0.0 , MetallicAddLightMask57);
				float4 AddLight233 = ( ( ( Cloth1157 * ClothRim1194 ) + ( Cloth2172 * ClothRim2200 ) + ( Pizi175 * PiZiRim213 ) + lerpResult249 ) * Base34 );
				float InnerLine59 = break61.a;
				float4 temp_output_45_0 = ( ( lerpResult141 + ( Specular86 * ( 1.0 - _BrightDarkLerp ) ) + AddLight233 ) * InnerLine59 );
				float2 uv_Decal = i.ase_texcoord1.xy * _Decal_ST.xy + _Decal_ST.zw;
				float4 Decal47 = tex2D( _Decal, uv_Decal );
				float4 lerpResult52 = lerp( temp_output_45_0 , ( temp_output_45_0 * Decal47 ) , _DecalLerp);
				float4 Final32 = lerpResult52;
				float4 temp_cast_0 = (tex2DNode2.a).xxxx;
				#if defined(_DEBUG2_MASK_R)
				float staticSwitch23 = tex2DNode22.r;
				#elif defined(_DEBUG2_MASK_G)
				float staticSwitch23 = tex2DNode22.g;
				#elif defined(_DEBUG2_MASK_B)
				float staticSwitch23 = tex2DNode22.b;
				#elif defined(_DEBUG2_MASK_A)
				float staticSwitch23 = tex2DNode22.a;
				#elif defined(_DEBUG2_VC_R)
				float staticSwitch23 = i.ase_color.r;
				#elif defined(_DEBUG2_VC_G)
				float staticSwitch23 = i.ase_color.g;
				#elif defined(_DEBUG2_VC_B)
				float staticSwitch23 = i.ase_color.b;
				#elif defined(_DEBUG2_VC_A)
				float staticSwitch23 = i.ase_color.a;
				#else
				float staticSwitch23 = tex2DNode22.r;
				#endif
				float4 temp_cast_1 = (staticSwitch23).xxxx;
				#if defined(_DEBUG3_NORMAL)
				float3 staticSwitch25 = i.ase_normal;
				#elif defined(_DEBUG3_TANGENT)
				float3 staticSwitch25 = i.ase_tangent.xyz;
				#else
				float3 staticSwitch25 = i.ase_normal;
				#endif
				float4 temp_cast_3 = (Specular86).xxxx;
				#if defined(_DEBUG_NONE)
				float4 staticSwitch19 = Final32;
				#elif defined(_DEBUG_BASE)
				float4 staticSwitch19 = tex2DNode2;
				#elif defined(_DEBUG_BASE_A)
				float4 staticSwitch19 = temp_cast_0;
				#elif defined(_DEBUG_SHADOW)
				float4 staticSwitch19 = tex2DNode16;
				#elif defined(_DEBUG_DEBUG2)
				float4 staticSwitch19 = temp_cast_1;
				#elif defined(_DEBUG_DEBUG3)
				float4 staticSwitch19 = float4( staticSwitch25 , 0.0 );
				#elif defined(_DEBUG_SPECULAR)
				float4 staticSwitch19 = temp_cast_3;
				#elif defined(_DEBUG_ADDLIGHT)
				float4 staticSwitch19 = AddLight233;
				#else
				float4 staticSwitch19 = Final32;
				#endif
				
				
				finalColor = staticSwitch19;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18800
29.6;924;1592;1002.2;487.2806;-3039.857;1;True;False
Node;AmplifyShaderEditor.SamplerNode;22;-98.06802,281.8509;Inherit;True;Property;_MaskMap;MaskMap;5;0;Create;True;0;0;0;False;0;False;-1;727944b6083a89a4190bcce0fae3934e;727944b6083a89a4190bcce0fae3934e;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;256;1.026398,6181.309;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;206;55.3111,6007.042;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;234.163,281.788;Inherit;False;MaskMap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-813.2313,899.7524;Inherit;False;54;MaskMap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;257;230.545,6096.463;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;61;-613.4927,913.4433;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;2;333.1736,-134.5576;Inherit;True;Property;_BaseMap;BaseMap;3;0;Create;True;0;0;0;False;0;False;-1;debeb745adad58743a0b5b866f24d05b;debeb745adad58743a0b5b866f24d05b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;258;400.545,6067.463;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;205;202.3111,5814.042;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;209;680.2744,6099.587;Inherit;False;Property;_MetallicViewLight_Scale;MetallicViewLight_Scale;24;0;Create;True;0;0;0;False;0;False;1;0.9;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;204;583.311,5891.042;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-272.7879,1010.797;Inherit;False;SpecularMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;759.2258,-38.02829;Inherit;False;Layer;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;210;611.2233,6197.298;Inherit;False;Property;_MetallicViewLight_StepValue;MetallicViewLight_StepValue;25;0;Create;True;0;0;0;False;0;False;0.5;0.56;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;207;636.6962,6019.927;Inherit;False;Property;_MetallicViewLight_Exp;MetallicViewLight_Exp;23;0;Create;True;0;0;0;False;0;False;1;2.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;253;-308.2758,4648.688;Inherit;False;266.4;160.3999;return(value>0.64 && value<0.7) ;1;170;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;255;1035.202,6270.219;Inherit;False;58;SpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;82;183.2468,3481.385;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;202;1015.311,5875.042;Inherit;False;PowerScaleStep;-1;;32;ff9322dd9f1b0044e948bc5b5de328f8;0;4;3;FLOAT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;7;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;145;-567.1339,4526.764;Inherit;False;35;Layer;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;81;139.2468,3643.385;Inherit;False;Blinn-Phong Half Vector;-1;;31;91a149ac9d615be429126c95e20753ce;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;211;990.9388,6137.754;Inherit;False;Property;_MetallicViewLight_Intensity;MetallicViewLight_Intensity;26;0;Create;True;0;0;0;False;0;False;1;0.7;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;196;657.1035,5081.906;Inherit;False;Property;_Cloth2_StepScale;Cloth2_StepScale;20;0;Create;True;0;0;0;False;0;False;1;1.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;199;631.4091,5274.159;Inherit;False;Property;_Cloth2_StepIntensity;Cloth2_StepIntensity;21;0;Create;True;0;0;0;False;0;False;1;0.36;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;252;-303.2758,4457.688;Inherit;False;266.4;160.3999;return (value>0.3 && value<0.5) ;1;168;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;201;1303.311,5891.042;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;188;648.4332,4634.775;Inherit;False;Property;_Cloth1_StepScale;Cloth1_StepScale;16;0;Create;True;0;0;0;False;0;False;1;1.07;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;195;626.0737,5191.269;Inherit;False;Property;_Cloth2_RimeStepValue;Cloth2_RimeStepValue;22;0;Create;True;0;0;0;False;0;False;1;0.65;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;216;620.5877,5471.368;Inherit;False;Property;_PiZiRim_StepScale;PiZiRim_StepScale;28;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;247;-762.8348,657.2246;Inherit;False;Constant;_Float2;Float 2;32;0;Create;True;0;0;0;False;0;False;0.2;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;254;-301.2758,4827.688;Inherit;False;266.4;160.3999;return(value>0.7) ;1;171;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;192;620.9683,4742.949;Inherit;False;Property;_Cloth1_RimeStepValue;Cloth1_RimeStepValue;18;0;Create;True;0;0;0;False;0;False;1;0.41;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;217;618.5877,5385.532;Inherit;False;Property;_PiZiRim_StepExp;PiZiRim_StepExp;27;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;251;-300.2758,4255.688;Inherit;False;266.4;160.3999;return(value<0.3) ;1;167;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;83;433.2468,3543.385;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;187;646.4332,4548.776;Inherit;False;Property;_Cloth1_StepExp;Cloth1_StepExp;15;0;Create;True;0;0;0;False;0;False;1;2.17;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;215;589.5579,5582.082;Inherit;False;Property;_PiZiRim_RimeStepValue;PiZiRim_RimeStepValue;30;0;Create;True;0;0;0;False;0;False;1;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;214;594.8933,5664.972;Inherit;False;Property;_PiZiRim_StepIntensity;PiZiRim_StepIntensity;29;0;Create;True;0;0;0;False;0;False;1;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;655.1035,4994.719;Inherit;False;Property;_Cloth2_StepExp;Cloth2_StepExp;19;0;Create;True;0;0;0;False;0;False;1;2.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;189;622.7388,4827.028;Inherit;False;Property;_Cloth1_StepIntensity;Cloth1_StepIntensity;17;0;Create;True;0;0;0;False;0;False;1;0.52;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;170;-270.2758,4700.688;Inherit;False;return(value>0.64 && value<0.7)@;1;False;1;True;value;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;218;963.0857,5429;Inherit;False;StepRimLight;-1;;62;7f102e938816df3479b4069da851fc7f;0;4;7;FLOAT;1;False;8;FLOAT;1;False;12;FLOAT;0;False;10;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;91;491.4021,3797.884;Inherit;False;Property;_SpecularScale;SpecularScale;12;0;Create;True;0;0;0;False;0;False;1;3.55;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;171;-252.2758,4877.688;Inherit;False;return(value>0.7)@;1;False;1;True;value;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;79;-312.041,825.283;Inherit;False;403.8;167.4;金属ViewLightMask，此金属部分不需要ViewLight;1;57;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;30;-524.3928,3191.792;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StepOpNode;248;-480.4858,722.0056;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;18;-40.52219,476.382;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;1506.939,5895.754;Inherit;False;MetallicViewLight;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;168;-253.2758,4507.688;Inherit;False;return (value>0.3 && value<0.5)@;1;False;1;True;value;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;198;999.6017,5038.187;Inherit;False;StepRimLight;-1;;58;7f102e938816df3479b4069da851fc7f;0;4;7;FLOAT;1;False;8;FLOAT;1;False;12;FLOAT;0;False;10;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;167;-250.2758,4305.688;Inherit;False;return(value<0.3)@;1;False;1;True;value;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;29;-556.3928,3031.791;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;90;510.4021,3654.884;Inherit;False;Property;_SpecularExp;SpecularExp;10;0;Create;True;0;0;0;False;0;False;4;5.88;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;84;566.2468,3551.385;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;174;138.4092,4573.559;Inherit;False;Metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;193;990.9314,4591.056;Inherit;False;StepRimLight;-1;;60;7f102e938816df3479b4069da851fc7f;0;4;7;FLOAT;1;False;8;FLOAT;1;False;12;FLOAT;0;False;10;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;16;333.104,64.48862;Inherit;True;Property;_ShadowMap;ShadowMap;4;0;Create;True;0;0;0;False;0;False;-1;f973318835b7cf246a87efb4e3bdeda1;f973318835b7cf246a87efb4e3bdeda1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;175;141.4092,4698.559;Inherit;False;Pizi;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;36;761.4258,90.57171;Inherit;False;Shadow;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;213;1333.469,5430.286;Inherit;False;PiZiRim;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;200;1322.707,5044.875;Inherit;False;ClothRim2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;215.69,662.5942;Inherit;False;AO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;85;772.2467,3561.385;Inherit;False;PowerScale;-1;;64;5ba70760a40e0a6499195a0590fd2e74;0;3;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;96;789.4987,3458.568;Inherit;False;Property;_SpucularStep;SpucularStep;13;0;Create;True;0;0;0;False;0;False;0;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;157;154.5832,4331.213;Inherit;False;Cloth1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;227;1369.675,2946.219;Inherit;False;212;MetallicViewLight;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;34;766.5258,-145.2283;Inherit;False;Base;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-282.5701,668.6639;Inherit;False;RampOffset;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;-264.01,883.3018;Inherit;False;MetallicAddLightMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;28;-300.3931,3095.792;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;172;143.4092,4450.559;Inherit;False;Cloth2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;226;1215.133,2924.692;Inherit;False;174;Metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;194;1377.988,4585.718;Inherit;False;ClothRim1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;-735.5722,2394.113;Inherit;False;57;MetallicAddLightMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;120;-726.1802,2521.776;Inherit;False;115;AO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;222;1398.722,2692.122;Inherit;False;200;ClothRim2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;95;1043.499,3502.568;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;131;-548.4197,2110.01;Inherit;False;Property;_ThresholdSecond;ThresholdSecond;7;0;Create;True;0;0;0;False;0;False;0;-0.35;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;100;-547.9674,1231.044;Inherit;False;34;Base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-520.9675,1349.044;Inherit;False;36;Shadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;99;836.4987,3823.568;Inherit;False;Property;_SpecularIntensity;SpecularIntensity;11;0;Create;True;0;0;0;False;0;False;4;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;102;1189.895,3233.038;Inherit;False;57;MetallicAddLightMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-471.1,1591.4;Inherit;False;Property;_Threshold;Threshold;6;0;Create;True;0;0;0;False;0;False;0;0.24;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;244;-692.8818,1477.077;Inherit;False;Constant;_Float0;Float 0;32;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;64;-490.3224,1719.911;Inherit;False;60;RampOffset;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;220;1212.722,2689.122;Inherit;False;172;Cloth2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;223;1209.92,2770.031;Inherit;False;175;Pizi;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;224;1395.92,2783.031;Inherit;False;213;PiZiRim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;219;1210.455,2597.454;Inherit;False;157;Cloth1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;31;-150.0053,3096.487;Inherit;False;NL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;221;1401.901,2607.301;Inherit;False;194;ClothRim1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;231;1652.051,2928.962;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;250;1265.637,3131.247;Inherit;False;Constant;_Float1;Float 1;32;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-567.6422,2238.521;Inherit;False;60;RampOffset;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;129;-222.442,2138.02;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;-463.3965,2442.889;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;230;1669.088,2719.052;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;228;1700.445,2496.882;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;103;-234.6794,1304.521;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;87;1174.041,3739.771;Inherit;False;58;SpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;229;1698.018,2613.343;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;125;-568.7409,2739.162;Inherit;False;Property;_BrightDarkLerp;BrightDarkLerp;14;0;Create;True;0;0;0;False;0;False;0;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;63;-145.1222,1619.41;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;1215.499,3538.568;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;132;-272.8734,2250.798;Inherit;False;31;NL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;249;1682.238,3096.147;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-195.5537,1732.189;Inherit;False;31;NL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;124;-180.2975,2460.034;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;133;-39.13286,2157.356;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;232;2011.684,2666.81;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;89;1385.602,3544.184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;41;23.1871,1636.747;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-53.25369,1296.256;Inherit;False;Gray;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;236;1949.658,2844.551;Inherit;False;34;Base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;136;238.0317,2135.945;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;250.3476,1821.411;Inherit;False;36;Shadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;233.5536,1655.744;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;242.8004,1903.821;Inherit;False;104;Gray;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;39;210.3259,1486.694;Inherit;False;34;Base;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;237;2343.658,2778.551;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;40;230.4231,1386.802;Inherit;False;36;Shadow;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;86;1629.101,3540.883;Inherit;False;Specular;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;42;571.3254,1436.975;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;126;949.4033,2131.704;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;233;2585.928,2751.133;Inherit;False;AddLight;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;94;914.3983,1978.473;Inherit;False;86;Specular;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;142;550.0511,2046.558;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;139;504.3573,1792.619;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;1210.77,1907.829;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;141;867.4861,1581.758;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;46;394.6976,1105.986;Inherit;True;Property;_Decal;Decal;8;0;Create;True;0;0;0;False;0;False;-1;fcbc7961f45d4154380c0cdac1e500cb;fcbc7961f45d4154380c0cdac1e500cb;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;234;1300.232,2102.323;Inherit;False;233;AddLight;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;59;-259.377,1126.054;Inherit;False;InnerLine;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;93;1422.191,1573.801;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;47;769.7453,1107.822;Inherit;False;Decal;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;2150.558,1755.955;Inherit;False;59;InnerLine;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;2306.618,1639.271;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;2378.09,1889.456;Inherit;False;47;Decal;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;53;2495.433,2045.128;Inherit;False;Property;_DecalLerp;DecalLerp;9;0;Create;True;0;0;0;False;0;False;0;0.61;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;2620.004,1768.601;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;52;2894.434,1680.128;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;26;455.2812,676.2744;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;32;3222.014,1945.047;Inherit;True;Final;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TangentVertexDataNode;27;310.2812,830.2744;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;243;1091.471,345.0206;Inherit;False;233;AddLight;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;25;784.2811,642.2744;Inherit;False;Property;_Debug3;Debug3;2;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;2;Normal;Tangent;Create;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;33;1130.819,-41.69049;Inherit;False;32;Final;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;92;876.4185,207.2136;Inherit;False;86;Specular;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;23;867.31,333.2357;Inherit;False;Property;_Debug2;Debug2;1;0;Create;True;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;8;Mask_R;Mask_G;Mask_B;Mask_A;VC_R;VC_G;VC_B;VC_A;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StickyNoteNode;128;-782.2585,1698.278;Inherit;False;150;100;New Note;;1,1,1,1;布料 皮革 金属;0;0
Node;AmplifyShaderEditor.StaticSwitch;19;1388.802,24.69918;Inherit;False;Property;_Debug;Debug;0;0;Create;False;0;0;0;False;0;False;0;0;0;True;;KeywordEnum;8;None;Base;Base_A;Shadow;Debug2;Debug3;Specular;AddLight;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;1978.834,252.7587;Float;False;True;-1;2;ASEMaterialInspector;100;1;NPR/NPR_GBVS_ASE;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;1;Above;NPR/OutLine/NORMAL;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;54;0;22;0
WireConnection;257;0;206;0
WireConnection;257;1;256;0
WireConnection;61;0;56;0
WireConnection;258;0;257;0
WireConnection;204;0;205;0
WireConnection;204;1;258;0
WireConnection;58;0;61;2
WireConnection;35;0;2;4
WireConnection;202;3;204;0
WireConnection;202;4;207;0
WireConnection;202;5;209;0
WireConnection;202;7;210;0
WireConnection;201;0;202;0
WireConnection;201;1;211;0
WireConnection;201;2;255;0
WireConnection;83;0;82;0
WireConnection;83;1;81;0
WireConnection;170;0;145;0
WireConnection;218;7;217;0
WireConnection;218;8;216;0
WireConnection;218;12;215;0
WireConnection;218;10;214;0
WireConnection;171;0;145;0
WireConnection;248;0;247;0
WireConnection;248;1;61;1
WireConnection;212;0;201;0
WireConnection;168;0;145;0
WireConnection;198;7;197;0
WireConnection;198;8;196;0
WireConnection;198;12;195;0
WireConnection;198;10;199;0
WireConnection;167;0;145;0
WireConnection;84;0;83;0
WireConnection;174;0;170;0
WireConnection;193;7;187;0
WireConnection;193;8;188;0
WireConnection;193;12;192;0
WireConnection;193;10;189;0
WireConnection;175;0;171;0
WireConnection;36;0;16;0
WireConnection;213;0;218;0
WireConnection;200;0;198;0
WireConnection;115;0;18;3
WireConnection;85;1;84;0
WireConnection;85;2;90;0
WireConnection;85;3;91;0
WireConnection;157;0;167;0
WireConnection;34;0;2;0
WireConnection;60;0;61;0
WireConnection;57;0;248;0
WireConnection;28;0;29;0
WireConnection;28;1;30;0
WireConnection;172;0;168;0
WireConnection;194;0;193;0
WireConnection;95;0;96;0
WireConnection;95;1;85;0
WireConnection;31;0;28;0
WireConnection;231;0;226;0
WireConnection;231;1;227;0
WireConnection;129;0;131;0
WireConnection;129;1;130;0
WireConnection;121;0;70;0
WireConnection;121;1;120;0
WireConnection;230;0;223;0
WireConnection;230;1;224;0
WireConnection;228;0;219;0
WireConnection;228;1;221;0
WireConnection;103;0;100;0
WireConnection;103;1;101;0
WireConnection;103;2;244;0
WireConnection;229;0;220;0
WireConnection;229;1;222;0
WireConnection;63;0;43;0
WireConnection;63;1;64;0
WireConnection;97;0;95;0
WireConnection;97;1;99;0
WireConnection;249;0;231;0
WireConnection;249;1;250;0
WireConnection;249;2;102;0
WireConnection;124;0;120;0
WireConnection;124;1;121;0
WireConnection;124;2;125;0
WireConnection;133;0;129;0
WireConnection;133;1;132;0
WireConnection;232;0;228;0
WireConnection;232;1;229;0
WireConnection;232;2;230;0
WireConnection;232;3;249;0
WireConnection;89;0;97;0
WireConnection;89;1;87;0
WireConnection;41;0;63;0
WireConnection;41;1;114;0
WireConnection;104;0;103;0
WireConnection;136;0;133;0
WireConnection;136;1;124;0
WireConnection;119;0;41;0
WireConnection;119;1;124;0
WireConnection;237;0;232;0
WireConnection;237;1;236;0
WireConnection;86;0;89;0
WireConnection;42;0;40;0
WireConnection;42;1;39;0
WireConnection;42;2;119;0
WireConnection;126;0;125;0
WireConnection;233;0;237;0
WireConnection;142;0;136;0
WireConnection;142;1;119;0
WireConnection;139;0;140;0
WireConnection;139;1;137;0
WireConnection;139;2;136;0
WireConnection;127;0;94;0
WireConnection;127;1;126;0
WireConnection;141;0;42;0
WireConnection;141;1;139;0
WireConnection;141;2;142;0
WireConnection;59;0;61;3
WireConnection;93;0;141;0
WireConnection;93;1;127;0
WireConnection;93;2;234;0
WireConnection;47;0;46;0
WireConnection;45;0;93;0
WireConnection;45;1;44;0
WireConnection;62;0;45;0
WireConnection;62;1;48;0
WireConnection;52;0;45;0
WireConnection;52;1;62;0
WireConnection;52;2;53;0
WireConnection;32;0;52;0
WireConnection;25;1;26;0
WireConnection;25;0;27;0
WireConnection;23;1;22;1
WireConnection;23;0;22;2
WireConnection;23;2;22;3
WireConnection;23;3;22;4
WireConnection;23;4;18;1
WireConnection;23;5;18;2
WireConnection;23;6;18;3
WireConnection;23;7;18;4
WireConnection;19;1;33;0
WireConnection;19;0;2;0
WireConnection;19;2;2;4
WireConnection;19;3;16;0
WireConnection;19;4;23;0
WireConnection;19;5;25;0
WireConnection;19;6;92;0
WireConnection;19;7;243;0
WireConnection;0;0;19;0
ASEEND*/
//CHKSM=DCA683DED79182DD9BEA117F9F1B8B8231B99669