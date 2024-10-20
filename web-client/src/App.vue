<template>
  <main :style="{display: 'flex', width: '100%', height: '100vh'}">
    <div :style="{flex: 1, display: 'flex', flexDirection: 'column'}">
      <select v-model="functionName" @change="triggerRequest()">
        <option v-for="name in functionNameOptions">{{ name }}</option>
      </select>
      <p :style="{
        // @ts-ignore
        color: zoom < minZoomForQuery ? 'red' : 'green'
      }">Zoom Level: {{ zoom?.toFixed(2) }}</p>
      <p>Search Radius: {{ extractedSearchRadius }} meter</p>
      <p v-if="displayedFeatures.length > 0">{{ displayedFeatures.length }} features found</p>

      <div :style="{flex: 1, overflowY: 'auto'}">
        <p v-for="feature in displayedFeatures" :key="feature" :style="{marginLeft: '10px', marginRight: '10px'}">
          <b>{{
          // @ts-ignore
          feature.geometry ? '' : 'No geometry, because outside of BBOX' }}
          </b>
          {{ feature }}
        </p>
      </div>
    </div>

    <OlMap id="map" :style="{flex: 1}"/>
  </main>
</template>

<script setup lang="ts">
import {  useGeographic } from 'ol/proj'
import { computed, onMounted, ref } from 'vue'
import { useOl, OlMap } from 'vue-ol-comp'
import TileLayer from 'ol/layer/Tile'
import 'ol/ol.css'
import VectorSource from 'ol/source/Vector'
import VectorLayer from 'ol/layer/Vector'

import {GeoJSON} from "ol/format"
import XYZ from 'ol/source/XYZ'
import { Feature } from 'ol'
import { Point, Polygon } from 'ol/geom'
import axios from 'axios'

useGeographic()

const minZoomForQuery = 14

const { map, onMapClick, extent, zoom } = useOl()
const displayedFeatures = ref([])
const functionName = ref("")
const functionNameOptions = ref([])
const clickedLatitude = ref(NaN)
const clickedLongitude = ref(NaN)

// @ts-ignore
const extractedSearchRadius = computed(() => Math.round(10 * Math.pow(1.5, 19 - zoom.value)))

const resultVectorSource = new VectorSource()
const pointDataSource = new VectorSource()

const reset = (() => {
  displayedFeatures.value = []
  resultVectorSource.clear()
  pointDataSource.clear()
})

const triggerRequest = () => {
  const url = `http://localhost:9000/functions/${functionName.value}/items.json`
  // @ts-ignore
  if (zoom.value < minZoomForQuery) {
    // @ts-ignore
    alert(`Zoom must be below ${minZoom}`)
    return
  }

  // @ts-ignore
  const [min_lon, min_lat, max_lon, max_lat ] = extent.value
  const latitude = clickedLatitude.value
  const longitude = clickedLongitude.value
  const radius = extractedSearchRadius.value

  axios(url, { params: { latitude, longitude, radius, min_lon, min_lat, max_lon, max_lat  }  })
  .then(response => response.data)
    .then(geojson => {

    const { features } = geojson
    displayedFeatures.value = features

    const olFeatures = new GeoJSON().readFeatures(geojson) as any // TODO: fix TS anys

    resultVectorSource.clear()
    resultVectorSource.addFeatures(olFeatures)

    pointDataSource.clear()
    pointDataSource.addFeature(new Feature({geometry: new Point([longitude, latitude])}))

  }).catch(()=>{
    reset()
  })

}

onMapClick((event) => {
  const [lon, lat] = event.coordinate
  clickedLatitude.value = lat
  clickedLongitude.value = lon
  triggerRequest()
})

onMounted(() => {

  axios('http://localhost:9000/functions.json')
    .then(response => response.data)
    .then((functionsInfo) => {
      // @ts-ignore
      functionNameOptions.value = functionsInfo.functions.map(item => item.id)
      functionName.value = functionNameOptions.value[0]
  })

  map.value.addLayer(
    new TileLayer({
      source: new XYZ(
        {
          url: "https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        }
      )
    })
    )

    map.value.addLayer(
      new VectorLayer({
        source:  resultVectorSource
      })
    )
    map.value.addLayer(
      new VectorLayer({
        source:  pointDataSource,
        style: {
          'circle-radius': 4,
          'circle-fill-color': 'red'
        }
      }),
    )

  axios('http://localhost:9000/collections/public.geom_nodes.json')
    .then(response => response.data)
    .then(collectionInfo => {
      console.log(collectionInfo);

      const bbox = collectionInfo.extent.spatial.bbox

      map.value.getView().fit(bbox)
      map.value.getView().setZoom(minZoomForQuery + 1)

      const coordinates = [
        [
          [bbox[0], bbox[1]], // bottom-left
          [bbox[2], bbox[1]], // bottom-right
          [bbox[2], bbox[3]], // top-right
          [bbox[0], bbox[3]], // top-left
          [bbox[0], bbox[1]]  // close the polygon
        ]
      ];

      const bboxLayer = new VectorLayer({
        source: new VectorSource({ features: [new Feature({ geometry: new Polygon(coordinates) })] }),
        style: {
          'stroke-color': 'gray',
          'stroke-width': 3
        }
      })

      map.value.addLayer(bboxLayer)


    })

})


</script>
