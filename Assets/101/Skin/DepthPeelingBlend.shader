Shader "Hidden/DepthPeelingBlend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "SardineRenderPipeline"
        }
        
        CGINCLUDE
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _CameraDepthTexture;
            sampler2D _DepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 color = tex2D(_MainTex, i.uv);
                //头发的深度
                float depth = tex2D(_DepthTex, i.uv);
                //场景不透明物体的深度
                float cameraDepth = tex2D(_CameraDepthTexture, i.uv);
                //去掉头发被遮挡的部分
                if(cameraDepth>depth)discard;
                //不是头发的 背景颜色部分
                if(depth==0)discard;
                
                return color;
            }
        ENDCG

        //与后层的颜色RT混合
        Pass
        {
//            Blend SrcAlpha OneMinusSrcAlpha
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        
        //第一次混合，与黑色混合
        Pass
        {
//            Blend SrcAlpha OneMinusSrcAlpha
            Blend SrcColor Zero
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
