using System;
using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using Random = UnityEngine.Random;

public struct ObjData
{
    public Vector3 position;
    public Quaternion rotation;
    public Vector3 scale;

    public Matrix4x4 matrix
    {
        get
        {
            return Matrix4x4.TRS(position, rotation, scale);
        }
    
    }
}
public class InstanceTest : MonoBehaviour
{
    public Mesh mesh;
    public Material mt;
    public int instances = 1000;
    public float radius = 10;
    
    private List<ObjData> batches = new List<ObjData>();
    private MaterialPropertyBlock mpb;
    private void Start()
    {
        mpb = new MaterialPropertyBlock();
        ObjData[] data = new ObjData[instances];
        for (int i = 0; i < instances; i++)
        {
            var pos = Random.insideUnitCircle * radius;

            data[i].position = pos;
            data[i].rotation = Quaternion.Euler(Random.Range(0, 360), Random.Range(0, 360), Random.Range(0, 360));
            data[i].scale = Vector3.one * Random.Range(0.5f, 2);
            mpb.SetColor("_InsColor",Random.ColorHSV());
            
        }
        batches.AddRange(data);
        
        
    }

    void Update()
    {
        
        Graphics.DrawMeshInstanced(mesh, 0, mt, batches.ConvertAll(x => x.matrix),mpb);
    }
}
