using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class CameraEffect : MonoBehaviour
{
    public Material material;
    
    void Update()
    {
        float[] bands = AudioEngine.audioBandBuffer;
        // grab the mesh off the game object and send the bands to the shader
        material.SetFloatArray("_Bands", bands);
    }
    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {    
        Graphics.Blit(src, dest, material);
    }
}