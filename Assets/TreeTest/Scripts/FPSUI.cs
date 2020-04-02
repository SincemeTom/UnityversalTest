using UnityEngine;
using UnityEngine.UI;

public class FPSUI : MonoBehaviour
{
    public float f_UpdateInterval = 0.5F;
    private float f_LastInterval;
    private int i_Frames = 0;
    private Text thisText;
    void Start()
    {
        Application.targetFrameRate=60;
        thisText = this.gameObject.GetComponent<Text>();
        f_LastInterval = Time.realtimeSinceStartup;
        i_Frames = 0;
    }

    void Update()
    {
        ++i_Frames;
        if (Time.realtimeSinceStartup > f_LastInterval + f_UpdateInterval)
        {
            float f_Fps = i_Frames / (Time.realtimeSinceStartup - f_LastInterval);
            i_Frames = 0;
            f_LastInterval = Time.realtimeSinceStartup;
            if (thisText != null) thisText.text = "FPS：" + f_Fps.ToString("f2");
        }
    }

}