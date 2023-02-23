using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
//https://github.com/iryoku/separable-sss/blob/master/Demo/Code/SeparableSSS.cpp
public class SeparableSSSS : ScriptableRendererFeature
{
    [System.Serializable]
    public class  Setting
    {
        public bool DebugSkin =false;
        public bool DisableSkinShLighting =false;
        [Range(0,5)]
        public float SubsurfaceScaler = 0.25f;
        public Color SubsurfaceColor = new Color(0.48f, 0.41f, 0.28f,1f);
        public Color SubsurfaceFalloff= new Color(1.0f, 0.37f, 0.3f,1f) ;
        public float MaxDistance;
    }
    
    public Setting setting;
    class CustomRenderPass : ScriptableRenderPass
    {
        public Setting setting;
        private static List<Vector4> KernelArray = new List<Vector4>();
        
        static int ID_DiffuseColor = Shader.PropertyToID("_DiffuseColor");
        static int ID_BlurTemp = Shader.PropertyToID("_BlurTempColor");
        static int ID_SkinDepthRT = Shader.PropertyToID("_SkinDepthRT");
        // private RenderTargetHandle Handle_SkinDiffuseRT;
        // private RenderTargetHandle Handle_BlurRT;
        
        static int ID_Kernel = Shader.PropertyToID("_Kernel");
        static int ID_ScreenSize = Shader.PropertyToID("_ScreenSize");
        static int ID_SSSScaler = Shader.PropertyToID("_SSSScale");
        static int ID_FOV = Shader.PropertyToID("_FOV");
        static int ID_MaxDistance = Shader.PropertyToID("_MaxDistance");
        
        
        public Material blurMaterial;
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            int pixelWidth = renderingData.cameraData.camera.pixelWidth;
            int pixelHeight = renderingData.cameraData.camera.pixelHeight;
            
            //计算出SSSBlur的kernel参数
            Vector3 SSSC = Vector3.Normalize(new Vector3 (setting.SubsurfaceColor.r, setting.SubsurfaceColor.g, setting.SubsurfaceColor.b));
            Vector3 SSSFC = Vector3.Normalize(new Vector3 (setting.SubsurfaceFalloff.r, setting.SubsurfaceFalloff.g, setting.SubsurfaceFalloff.b));
            // if(KernelArray.Count == 0) 
            SeparableSSSLibrary.CalculateKernel(KernelArray, 32, SSSC, SSSFC);


            // renderingData.cameraData.cameraTargetDescriptor.enableRandomWrite = true;
            blurMaterial = new Material(Shader.Find("Hidden/SeparableSubsurfaceScatter"));
            
            blurMaterial.SetVectorArray(ID_Kernel, KernelArray);
            blurMaterial.SetVector(ID_ScreenSize, new Vector4(pixelWidth, pixelHeight, 1f/pixelWidth, 1f/pixelHeight));
            blurMaterial.SetFloat(ID_SSSScaler,setting.SubsurfaceScaler);
            blurMaterial.SetFloat(ID_FOV,renderingData.cameraData.camera.fieldOfView);
            blurMaterial.SetFloat(ID_MaxDistance,setting.MaxDistance);
            
            cmd.GetTemporaryRT(ID_DiffuseColor, pixelWidth, pixelHeight, 0);
            cmd.GetTemporaryRT(ID_BlurTemp, pixelWidth, pixelHeight, 0);
            cmd.GetTemporaryRT(ID_SkinDepthRT,pixelWidth, pixelHeight, 24, FilterMode.Point, RenderTextureFormat.Depth);
            
            ConfigureTarget(ID_DiffuseColor,ID_SkinDepthRT);
            ConfigureClear(ClearFlag.All, Color.black);
            
            
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //1.绘制diffuse
            //2.blur (diffuse) X Y
            //3.finally diffuse * baseMap + specular  正常渲染  
            var cmd = CommandBufferPool.Get("SeparableSSSS");
            var drawingSettings = CreateDrawingSettings(new ShaderTagId("SkinSSSSDiffuse"), ref renderingData, SortingCriteria.CommonOpaque);
            
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            
            //1
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
            //2 blur x
            cmd.Blit(ID_DiffuseColor, ID_BlurTemp, blurMaterial, 0);
            cmd.Blit(ID_BlurTemp, ID_DiffuseColor, blurMaterial, 1);
            
            context.ExecuteCommandBuffer(cmd);

            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(ID_BlurTemp);
            cmd.ReleaseTemporaryRT(ID_DiffuseColor);
            cmd.ReleaseTemporaryRT(ID_SkinDepthRT);
        }
    }

    CustomRenderPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
        m_ScriptablePass.setting = setting;
        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;//皮肤是Opaque
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


