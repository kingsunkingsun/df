using UnityEngine;
using UnityEngine.SceneManagement;

using System.Collections;

public class MenuController : MonoBehaviour {

	public void LoadScene (string name) {
		SceneManager.LoadScene(name);
		DynamicGI.UpdateEnvironment();
	}

	public void Exit () {
#if UNITY_EDITOR
		if (UnityEditor.EditorApplication.isPlaying)
			UnityEditor.EditorApplication.isPlaying = false;
		else
#endif
		Application.Quit();
	}

}
