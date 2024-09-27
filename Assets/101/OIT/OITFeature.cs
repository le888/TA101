using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Color = System.Drawing.Color;

public class OITFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Setting
    {
        [Range(1, 16)] public int DepthPeelingPass = 6;
    }
    
    public Setting setting;
    
    class CustomRenderPass : ScriptableRenderPass
    {
        public Setting setting;
        private static int ID_DepthPeelingPassCount = Shader.PropertyToID("_DepthPeelingPassCount");
        private static int ID_MaxDepth = Shader.PropertyToID("_MaxDepthTex");
        private Material DepthPeelingBlendMaterial;
        
        private Material GetDepthPeelingBlendMaterial()
        {
            if (DepthPeelingBlendMaterial == null)
            {
                DepthPeelingBlendMaterial = new Material(Shader.Find("Hidden/DepthPeelingBlend"));
            }
            return DepthPeelingBlendMaterial;
        }
        
        public static void NAME()
        {
            
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            int DepthPeelingPass = setting.DepthPeelingPass;
            int pixelWidth = renderingData.cameraData.camera.pixelWidth;
            int pixelHeight = renderingData.cameraData.camera.pixelHeight;
            
            var drawingSettings = CreateDrawingSettings(new ShaderTagId("DepthPeelingPass"), ref renderingData, SortingCriteria.CommonOpaque);
            var filteringSettings = new FilteringSettings(RenderQueueRange.transparent);
            
            var cmd = CommandBufferPool.Get("OITFeature");
            using (new ProfilingSample(cmd, "OITFeature"))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                List<int> colorRTs = new List<int>(DepthPeelingPass);
                List<int> depthRTs = new List<int>(DepthPeelingPass);
                for (int i = 0; i < DepthPeelingPass; i++)
                {
                    colorRTs.Add(Shader.PropertyToID("_ColorRT" + i));//_ColorRT0
                    depthRTs.Add(Shader.PropertyToID("_DepthRT" + i));//_DepthRT0
                    cmd.GetTemporaryRT(colorRTs[i], pixelWidth, pixelHeight, 0);
                    cmd.GetTemporaryRT(depthRTs[i], pixelWidth, pixelHeight, 32, FilterMode.Point, RenderTextureFormat.RFloat);

                    cmd.SetGlobalInt(ID_DepthPeelingPassCount, i);
                    //如果不是第一层，需要传入上一层的深度纹理
                    if (i>0)
                    {
                        cmd.SetGlobalTexture(ID_MaxDepth, depthRTs[i - 1]);
                    }
                    //设置MRT(multi render target) 颜色RT   深度RT
                    cmd.SetRenderTarget(new RenderTargetIdentifier[]{colorRTs[i], depthRTs[i]}, depthRTs[i]);
                    cmd.ClearRenderTarget(true,true,UnityEngine.Color.black);
                    context.ExecuteCommandBuffer(cmd);
                    cmd.Clear();
                    //渲染我们指定的shader tag 物体
                    context.DrawRenderers(renderingData.cullResults,ref drawingSettings,ref filteringSettings);
                }

                for (int i = DepthPeelingPass - 1; i >= 0; i--)
                {
                    cmd.SetGlobalTexture("_DepthTex", depthRTs[i]);
                    int pass = 0;
                    //第一次Blend时,与黑色Blend
                    if (i == DepthPeelingPass - 1)
                        pass = 1;
                    
                    cmd.Blit(colorRTs[i], renderingData.cameraData.renderer.cameraColorTarget, GetDepthPeelingBlendMaterial(), pass);
                
                    cmd.ReleaseTemporaryRT(depthRTs[i]);
                    cmd.ReleaseTemporaryRT(colorRTs[i]);
                }
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
               
            }
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
            cmd.Clear();
            
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
    
        // Configures where the render pass should be injected.
        m_ScriptablePass.setting = setting;
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


