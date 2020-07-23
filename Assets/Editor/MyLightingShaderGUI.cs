using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class MyLightingShaderGUI : ShaderGUI
{
	static GUIContent staticLabel = new GUIContent();
	private MaterialEditor editor;
	private MaterialProperty[] properties;
	private Material target;
	
	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
	{
		this.target = materialEditor.target as Material;
		this.editor = materialEditor;
		this.properties = properties;
		DoMain();
		DoSecond();
	}

	void DoMain()
	{
		GUILayout.Label("Main Maps", EditorStyles.boldLabel);
		
		MaterialProperty mainTex = FindProperty("_MainTex");
		editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, FindProperty("_Tint"));
		DoMatellic();
		DoSmoothness();
		DoNormals();
		editor.TextureScaleOffsetProperty(mainTex);
	}

	void DoSecond()
	{
		GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

		MaterialProperty detailTex = FindProperty("_DetailTex");
		editor.TexturePropertySingleLine(MakeLabel(detailTex, "Albedo (RGB) multiplied by 2"), detailTex);
		DoSecondaryNormals();
		editor.TextureScaleOffsetProperty(detailTex);
	}
	
	void DoMatellic()
	{
		MaterialProperty map = FindProperty("_MetallicMap");
		EditorGUI.BeginChangeCheck();
		editor.TexturePropertySingleLine(MakeLabel(map, "Metallic (R)"), map, map.textureValue ? null : FindProperty("_Metallic"));
		if (EditorGUI.EndChangeCheck())
		{
			SetKeyword("_METALLIC_MAP", map.textureValue);
		}
	}

	void SetKeyword(string keyword, bool state)
	{
		if (state)
		{
			target.EnableKeyword(keyword);
		}
		else
		{
			target.DisableKeyword(keyword);
		}
	}
	
	void DoSmoothness()
	{
		MaterialProperty slider = FindProperty("_Smoothness");
		EditorGUI.indentLevel += 2;
		editor.ShaderProperty(slider, MakeLabel(slider));
		EditorGUI.indentLevel -= 2;
	}
	
	void DoNormals()
	{
		MaterialProperty map = FindProperty("_NormalMap");
		editor.TexturePropertySingleLine(MakeLabel(map), map, 
			map.textureValue ? FindProperty("_BumpScale") : null);
	}

	void DoSecondaryNormals()
	{
		MaterialProperty map = FindProperty("_DetailNormalMap");
		editor.TexturePropertySingleLine(MakeLabel(map), map,
			map.textureValue ? FindProperty("_DetailBumpScale") : null);
	}

	MaterialProperty FindProperty(string name)
	{
		return FindProperty(name, properties);
	}

	static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
	{
		staticLabel.text = property.displayName;
		staticLabel.tooltip = tooltip;
		return staticLabel;
	}
}
