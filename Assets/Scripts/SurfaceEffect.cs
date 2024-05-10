using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteInEditMode]
public class SurfaceEffect : MonoBehaviour
{
    public Material material;
    
    void Update()
    {
        float[] bands = AudioEngine.audioBandBuffer;
        // grab the mesh off the game object and send the bands to the shader
        material.SetFloatArray("_Bands", bands);
    }
}