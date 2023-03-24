using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RayMarching : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        Material m_Material;
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            m_Material = new Material(Shader.Find("Hidden/RayMarchingBox"));
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            var cmd = CommandBufferPool.Get("RayMarching");
            using (new ProfilingScope(cmd, new ProfilingSampler("RayMarching")))
            {
                cmd.Blit(renderingData.cameraData.renderer.cameraColorTarget, renderingData.cameraData.renderer.cameraColorTarget, m_Material);
                // cmd.DrawMesh(PrimitiveType.Cube, Matrix4x4.identity, m_Material, 0, 0;
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            


            //set up data
            // var drawSetting = CreateDrawingSettings(new ShaderTagId("RayMarching"), ref renderingData, SortingCriteria.CommonOpaque);
            // var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            // context.DrawRenderers(renderingData.cullResults, ref drawSetting, ref filteringSettings);
           
            
            
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
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


