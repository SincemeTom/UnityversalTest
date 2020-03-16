using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.Rendering.Universal.Internal
{
    [ExecuteInEditMode]
    public class SceneSettings : MonoBehaviour
    {

        public delegate void OnNewScene(SceneSettings sceneSettings);
        public static event OnNewScene handlerOnNewScene;

        public static SceneSettings m_CurrentSceneSettings;
        public static SceneSettings CurrentSceneSettings
        {
            get { return m_CurrentSceneSettings; }
            set
            {
                m_CurrentSceneSettings = value;
                if (handlerOnNewScene != null)
                    handlerOnNewScene(m_CurrentSceneSettings);
            }
        }
        void OnEnable()
        {
            m_CurrentSceneSettings = this;
        }
        void OnDisable()
        {
            m_CurrentSceneSettings = null;
        }

        public CharacterShadow m_CharacterShadow;
        // Start is called before the first frame update
        void Start()
        {

        }

        // Update is called once per frame
        void Update()
        {

        }
    }
}