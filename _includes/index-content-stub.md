{% if site.debug %}
site: {{ site }}
<pre>DEBUG: Site object dump: {{ site | dump }}</pre>
{% endif %}

{% assign sorted_content = site.site_content | sort: "order" %}
{% for a_page in sorted_content %}
  <h2>
    <a href="{{ site.baseurl }}{{ a_page.url }}">
      {{ a_page.title }}
    </a>
  </h2>
  {% comment %}
  <p>{{ a_page.content | markdownify }}</p>
  {% endcomment %}
{% endfor %}
