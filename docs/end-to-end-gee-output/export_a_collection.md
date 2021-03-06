One of the most commonly asked questions by Earth Engine users is - *How do I download all images in a collection*? The Earth Engine API allows you to export a single image, but not collection of images. The recommended way to do batch exports like this is to use the Python API's `ee.batch.Export` functions and use a Python for-loop to iterate and export each image. The `ee.batch` module also gives you ability to control *Tasks* - allowing you to automate exports.


```python
import ee
```


```python
ee.Authenticate()
```


```python
ee.Initialize()
```

#### Create a Collection


```python
geometry = ee.Geometry.Point([107.61303468448624, 12.130969369851766])
s2 = ee.ImageCollection("COPERNICUS/S2")
rgbVis = {
  'min': 0.0,
  'max': 3000,
  'bands': ['B4', 'B3', 'B2'],
}

# Write a function for Cloud masking
def maskS2clouds(image):
  qa = image.select('QA60')
  cloudBitMask = 1 << 10
  cirrusBitMask = 1 << 11
  mask = qa.bitwiseAnd(cloudBitMask).eq(0).And(
             qa.bitwiseAnd(cirrusBitMask).eq(0))
  return image.updateMask(mask) \
      .select("B.*") \
      .copyProperties(image, ["system:time_start"])

filtered = s2 \
  .filter(ee.Filter.date('2019-01-01', '2020-01-01')) \
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 30)) \
  .filter(ee.Filter.intersects('.geo', geometry)) \
  .map(maskS2clouds)

# Write a function that computes NDVI for an image and adds it as a band
def addNDVI(image):
  ndvi = image.normalizedDifference(['B5', 'B4']).rename('ndvi')
  return image.addBands(ndvi)

withNdvi = filtered.map(addNDVI)
```

#### Export All Images

Exports are done via the ``ee.batch`` module. A key difference between javascript and Python version is that the `region` parameter needs to be supplied with actual geometry coordinates.


```python
image_ids = withNdvi.aggregate_array('system:index').getInfo()
print('Total images: ', len(image_ids))
```


```python
palette = [
  'FFFFFF', 'CE7E45', 'DF923D', 'F1B555', 'FCD163', '99B718',
  '74A901', '66A000', '529400', '3E8601', '207401', '056201',
  '004C00', '023B01', '012E01', '011D01', '011301'];

ndviVis = {'min':0, 'max':0.5, 'palette': palette }

# Export with 100m resolution for this demo
for i, image_id in enumerate(image_ids):
  image = ee.Image(withNdvi.filter(ee.Filter.eq('system:index', image_id)).first())
  task = ee.batch.Export.image.toDrive(**{
    'image': image.select('ndvi').visualize(**ndviVis),
    'description': 'Image Export {}'.format(i+1),
    'fileNamePrefix': image.id().getInfo(),
    'folder':'earthengine',
    'scale': 100,
    'region': image.geometry().getInfo()['coordinates'],
    'maxPixels': 1e10
  })
  task.start()
  print('Started Task: ', i+1)
```

#### Manage Running/Waiting Tasks

You can manage tasks as well. Get a list of tasks and get state information on them


```python
tasks = ee.batch.Task.list()
for task in tasks:
  task_id = task.status()['id']
  task_state = task.status()['state']
  print(task_id, task_state)
```

You can cancel tasks as well


```python
if task_state == 'RUNNING' or task_state == 'READY':
    task.cancel()
    print('Task {} canceled'.format(task_id))
else:
    print('Task {} state is {}'.format(task_id, task_state))

```
