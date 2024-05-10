using System.Collections;
using System.Collections.Generic;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UI;

public class PostEffects : MonoBehaviour
{
    public Shader postShader; 
    Material postEffectMaterial;
    public Color ScreenTint = Color.red;
    RenderTexture renderTexture;

    public float UpperFeather;
    public float LowerFeather;
    public float RippleIntensity;
    public float RippleSpeed;
    public AnimationCurve curve;
    
    void Update() {
        float[] bands = AudioEngine.audioBandBuffer;
        // grab the mesh off the game object and send the bands to the shader
        if (postEffectMaterial != null) postEffectMaterial.SetFloatArray("_AudioBands", bands);
        else Debug.Log("postEffectMaterial is null");
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (postEffectMaterial == null)
        {
            postEffectMaterial = new Material(postShader);
        }
        if (renderTexture == null) 
        {
            renderTexture = new RenderTexture(src.width, src.height, 0);
        }
        postEffectMaterial.SetColor("_ScreenTint", ScreenTint);
        postEffectMaterial.SetFloat("_UpperFeather", UpperFeather);
        postEffectMaterial.SetFloat("_LowerFeather", LowerFeather);
        postEffectMaterial.SetFloat("_RippleIntensity", RippleIntensity);
        postEffectMaterial.SetFloat("_RippleSpeed", RippleSpeed);

        // First Blit
        RenderTexture startRenderTexture = RenderTexture.GetTemporary(src.width, src.height);
        Graphics.Blit(src, startRenderTexture, postEffectMaterial);
        Graphics.Blit(startRenderTexture, dest);
        RenderTexture.ReleaseTemporary(startRenderTexture);
    }
}
