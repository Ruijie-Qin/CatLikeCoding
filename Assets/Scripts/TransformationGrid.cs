using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TransformationGrid : MonoBehaviour
{
	public Transform prefab;
	public int gridResolution = 10;
	
	private Transform[] _grid;
	private List<Transformation> _transformations;
	private Matrix4x4 _transformation;
	
	private void Awake()
	{
		_grid = new Transform[gridResolution * gridResolution * gridResolution];
		_transformations = new List<Transformation>();
		for (int i = 0, z = 0; z < gridResolution; z++)
		{
			for (int y = 0; y < gridResolution; y++)
			{
				for (int x = 0; x < gridResolution; x++, i++)
				{
					_grid[i] = CreateGridPoint(x, y, z);
				}
			}
		}
		prefab.gameObject.SetActive(false);
	}

	private Transform CreateGridPoint(int x, int y, int z)
	{
		Transform point = Instantiate<Transform>(prefab);
		point.localPosition = GetCoordinates(x, y, z);
		point.GetComponent<MeshRenderer>().material.color = new Color
		(
			(float)x / gridResolution,
			(float)y / gridResolution,
			(float)z / gridResolution
		);
		return point;
	}

	private Vector3 GetCoordinates(int x, int y, int z)
	{
		return new Vector3(
			x - (gridResolution - 1) * 0.5f,
			y - (gridResolution - 1) * 0.5f,
			z - (gridResolution - 1) * 0.5f
			);
	}

	private void Update()
	{
		UpdateTransformation();
		for (int i = 0, z = 0; z < gridResolution; z++)
		{
			for (int y = 0; y < gridResolution; y++)
			{
				for (int x = 0; x < gridResolution; x++, i++)
				{
					_grid[i].localPosition = TransformPoint(x, y, z);
				}
			}
		}
	}

	private void UpdateTransformation()
	{
		GetComponents<Transformation>(_transformations);
		if (_transformations.Count <= 0)
		{
			return;
		}

		_transformation = _transformations[0].Matrix;
		for (int i = 1; i < _transformations.Count; i++)
		{
			_transformation = _transformations[i].Matrix * _transformation;
		}
	}

	private Vector3 TransformPoint(int x, int y, int z)
	{
		Vector3 coordinates = GetCoordinates(x, y, z);
		return _transformation.MultiplyPoint(coordinates);
	}
}
