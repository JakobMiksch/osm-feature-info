<template>
    <h3 v-show="hasResults">{{ headline }}</h3>
    <p v-for="{geometry_type, osm_id, osm_type, tags, url, hidden} in results" :key="osm_id" :style="{marginLeft: '10px', marginRight: '10px'}">
        <h4>
        <a :href="url" target="_blank" :style="{marginRight: '5px'}">{{ osm_type }} {{ osm_id }}</a>
        <span v-if="hidden">(hidden)</span> <span>{{ geometry_type }}</span>
        </h4>
        <table>
        <tbody>
            <tr v-for="(value, key) in tags" :key="key">
            <td :style="{fontWeight: 'bold'}">{{ key }}</td>
            <td>{{ value }}</td>
            </tr>
        </tbody>
        </table>
    </p>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  results: any;
  headline: string;
}>();

const hasResults = computed(() => !!props.results.length);
</script>

<style scoped>
table, td {
  border: 1px solid #ddd;
  border-collapse: collapse;
  padding: 8px;
}
</style>
