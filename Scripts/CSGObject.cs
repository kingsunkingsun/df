using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

public class CSGObject : MonoBehaviour {

	public Material RealMaterial;

	public bool Complement;

	public Mesh Mesh {
		get { return GetComponent<MeshFilter>().sharedMesh; }
	}

	public Renderer Renderer {
		get { return GetComponent<Renderer>(); }
	}

	void Awake () {
		Renderer.enabled = false;
	}

	public void Render () {
		RealMaterial.SetInt("_Flip", Complement ? 1 : 0);
		RealMaterial.SetPass(0);
		Graphics.DrawMeshNow(Mesh, Renderer.localToWorldMatrix);
	}

}
