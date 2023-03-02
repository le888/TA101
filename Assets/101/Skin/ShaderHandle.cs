using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShaderHandle : MonoBehaviour
{
    public List<Shader> Shaders;

    private void Awake()
    {
        DontDestroyOnLoad(this);
    }
}
