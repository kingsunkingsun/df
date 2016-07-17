using System.Linq;

using UnityEngine;
using UnityEngine.Rendering;

public class CSGRenderer : MonoBehaviour {

	struct DrawRootResult {
		public RenderTexture color, depth;
	}

	public Material Material;
	public Transform[] Roots;

	new private Camera camera;

	void Awake () {
		camera = GetComponent<Camera>();
	}

	void OnPostRender () {
		var active = RenderTexture.active;
		var color = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0);
		var depth = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.RGFloat);
		var fdepth = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.RGFloat);
		Graphics.SetRenderTarget(depth);
		GL.Clear(false, true, Color.white);
		Graphics.SetRenderTarget(fdepth);
		GL.Clear(false, true, Color.white);
		foreach (var root in Roots) {
			if (root == null) continue;
			var r = DrawRoot(root);
			RenderTexture.active = color;
			Material.SetTexture("_MainTex", r.color);
			Material.SetTexture("_Depth1", depth);
			Material.SetTexture("_Depth2", r.depth);
			Draw(9);
			RenderTexture.active = fdepth;
			Material.SetTexture("_Depth1", depth);
			Draw(10);
			Graphics.Blit(fdepth, depth);
			r.color.Release();
			r.depth.Release();
		}
		RenderTexture.active = active;
		Material.SetTexture("_MainTex", color);
		Material.SetTexture("_Depth1", depth);
		Draw(11);
		color.Release();
		depth.Release();
		fdepth.Release();
	}

	DrawRootResult DrawRoot (Transform root) {
		var color = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 24);
		var depth = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 0, RenderTextureFormat.RGFloat);
		depth.filterMode = FilterMode.Point;
		var objects = root.GetComponentsInChildren<CSGObject>();
		Graphics.SetRenderTarget(depth);
		GL.Clear(false, true, Color.white);
		Graphics.SetRenderTarget(color);
		GL.Clear(true, false, Color.black, 0);
		DoIntersect(objects);
		DoSubtract(objects);
		DoSubtract(objects);
		DoZClip(objects);
		DoRender(objects);
		Graphics.SetRenderTarget(depth.colorBuffer, color.depthBuffer);
		DoRenderDepth(objects);
		var drr = new DrawRootResult();
		drr.color = color;
		drr.depth = depth;
		return drr;
	}

	void Draw (CSGObject obj, int pass, int _ref = -1) {
		if (_ref != -1) Material.SetInt("_Ref", _ref);
		Material.SetPass(pass);
		Graphics.DrawMeshNow(obj.Mesh, obj.Renderer.localToWorldMatrix);
	}

	void Draw (int pass, int _ref = -1) {
		if (_ref != -1) Material.SetInt("_Ref", _ref);
		Material.SetPass(pass);
		GL.PushMatrix();
		GL.LoadPixelMatrix(0, 1, 0, 1);
		GL.Begin(GL.QUADS);
		GL.Vertex3(0, 0, -1);
		GL.Vertex3(0, 1, -1);
		GL.Vertex3(1, 1, -1);
		GL.Vertex3(1, 0, -1);
		GL.End();
		GL.PopMatrix();
	}

	void DoIntersect (CSGObject[] objects) {
		foreach (var o in objects)
			if (!o.Complement) Draw(o, 0);
		if (objects.Count(x => !x.Complement) > 1) {
			foreach (var o in objects)
				if (!o.Complement) Draw(o, 1);
			Draw(2, objects.Count(x => !x.Complement));
		}
	}

	void DoSubtract (CSGObject[] objects) {
		int i = 0;
		foreach (var o in objects) {
			if (!o.Complement) continue;
			i = (i + 1) % 256;
			if (i == 0) Draw(3);
			Draw(o, 6, i);
			Draw(o, 7, i);
		}
		Draw(3);
	}

	void DoZClip (CSGObject[] objects) {
		Draw(3);
		foreach (var o in objects)
			if (!o.Complement) Draw(o, 4);
		Draw(5);
	}

	void DoRender (CSGObject[] objects) {
		foreach (var o in objects)
			o.Render();
	}

	void DoRenderDepth (CSGObject[] objects) {
		foreach (var o in objects)
			Draw(o, 8);
	}

}
