import Analytics from 'analytics' // https://www.npmjs.com/package/analytics
import snowplowPlugin from '@analytics/snowplow' // https://www.npmjs.com/package/@analytics/snowplow

return; // disable analytics

// https://github.com/snowplow/snowplow
// https://github.com/snowplow/snowplow-javascript-tracker
// https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-tracker/snowplow-plugin-for-analytics-npm-package/
const analytics = Analytics({
    app: 'rails-blog',
    plugins: [
        snowplowPlugin({
            name: 'snowplow',
            // https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-tracker/third-party-cdn-hosting/
            scriptSrc: 'https://cdn.jsdelivr.net/gh/snowplow/sp-js-assets@2.17.3/sp.js',
            collectorUrl: '127.0.0.1:3000',
            trackerSettings: {
                appId: 'blog',
                postPath: '/tracking',
                contexts: {
                    webPage: true
                }
            }
        })
    ]
})

// document.addEventListener('load', event => { // https://developer.mozilla.org/en-US/docs/Web/API/Window/load_event
// document.addEventListener('DOMContentLoaded', event => { // https://developer.mozilla.org/en-US/docs/Web/API/Document/DOMContentLoaded_event
window.onload = event => {
    console.log('onload', event)
    onPageLoad()

    /*document.addEventListener('page:load', event => {
        console.log('page:load', event)
    })*/
    document.addEventListener('turbolinks:load', event => {
        console.log('turbolinks:load', event)
        onPageLoad()
    })

    document.addEventListener('click', event => {
        // console.log('click', event)
        const node = event.target
        if (node.getAttribute('track-click')) {
            const eventName = node.getAttribute('track-click')
            const eventPayload = getJsonAttribute(node, 'track-payload')
            trackEvent(eventName, eventPayload)
        }
    });
}
window.addEventListener('beforeunload', event => {
    console.log('beforeunload', event)
})
window.addEventListener('unload', event => {
    console.log('unload', event)
})

function trackPage() {
    console.log('analytics.page()')
    analytics.page()
}

function trackEvent(name, payload) {
    console.log(`analytics.track(${name})`, payload)
    analytics.track(name, payload)
}

function trackIdentity(id, details) {
    console.log(`analytics.identify(${id})`, details)
    analytics.identify(id, details)
}

function onPageLoad() {
    const identity = document.querySelector('[track-id]')
    if (identity) {
        const identityId = identity.getAttribute('track-id')
        const identityDetails = getJsonAttribute(identity, 'track-payload')
        trackIdentity(identityId, identityDetails)
    }
    trackPage()
}

function getJsonAttribute(node, attr) {
    const value = node.getAttribute(attr) || undefined
    return (value || '').startsWith('{') ? JSON.parse(value) : value
}
