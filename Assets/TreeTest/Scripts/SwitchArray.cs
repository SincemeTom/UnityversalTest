using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SwitchArray : MonoBehaviour
{
    public Material[] mats;

    private Text thisText;

    private int matType = 0;

    MeshRenderer[] cubes;

    void Start()
    {
        cubes = GameObject.FindObjectsOfType<MeshRenderer>();

        thisText = this.gameObject.transform.Find("Text").GetComponent<Text>();

        SwitchFunc(0);
    }
    
    public void SwitchButton()
    {
        SwitchFunc((matType + 1) % mats.Length);
    }

    void SwitchFunc(int targetState)
    {
        if (targetState != matType)
        {
            matType = targetState;
            foreach (var cube in cubes)
            {
                if (cube)
                {
                    Material[] temp = cube.sharedMaterials;
                    temp[1] = mats[matType];
                    cube.sharedMaterials = temp;
                }
            }
        }
        string mateshadername = mats[matType].name;
        if (thisText != null) thisText.text = "使用材质" + mateshadername;
    }
}
