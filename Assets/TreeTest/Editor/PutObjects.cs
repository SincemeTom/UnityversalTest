using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class PutObjects
{
    static float rangeX = 4.0f;
    static float rangeY = 2.0f;

    [MenuItem("Tool/PutObjects")]
    public static void myfunc()
    {
        GameObject LoadObj = AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Prefabs/cube.prefab");

        if (LoadObj)
        {
            GameObject father = new GameObject();
            father.transform.position = new Vector3(0, 0, 0);
            father.name = "Objects";

            Debug.Log("获取到了");
            int maxX = 10;
            int maxY = 10;

            float distanceX = rangeX / maxX;
            float distanceY = rangeY / maxY;

            for (int i = 0; i < maxX; i++)
            {
                for (int j = 0; j < maxY; j++)
                {
                    Vector3 pos = new Vector3(-rangeX / 2 + i * distanceX, -rangeY / 2 + j * distanceY , 0);
                    GameObject temp = GameObject.Instantiate(LoadObj, pos, Quaternion.Euler(new Vector3(0, 0, 0)), father.transform);
                    temp.name = "Object" + (i * maxX + j).ToString();
                }
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
}
