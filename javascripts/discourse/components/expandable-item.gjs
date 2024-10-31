import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import { htmlSafe } from "@ember/template";
import DButton from "discourse/components/d-button";
import { categoryBadgeHTML } from "discourse/helpers/category-link";
import { ajax } from "discourse/lib/ajax";
import Category from "discourse/models/category";
import icon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";
import eq from "truth-helpers/helpers/eq";
import or from "truth-helpers/helpers/or";

export default class ExpandableItemComponent extends Component {
  @tracked isLoading = false;
  @tracked isOpen = false;
  @tracked loadedContent = [];

  getSlugPath = (category) => Category.slugFor(category);

  constructor() {
    super(...arguments);
  }

  @action
  async toggleContent() {
    this.isOpen = !this.isOpen;

    if (this.isOpen && !this.loadedContent.id) {
      this.isLoading = true;
      try {
        const response = await ajax(
          `/c/${this.args.slugPath}/find_by_slug.json`
        );

        this.loadedContent = response.category;
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error(
          `Error loading permissions for category ${this.args.slugPath}:`,
          error
        );
        this.loadedContent = [];
      } finally {
        this.isLoading = false;
      }
    }
  }

  get combinedLabel() {
    const badgeHTML = this.badge(this.args.catID); // `badge` als Methode
    const label = this.args.label;
    return htmlSafe(`${badgeHTML} ${label}`);
  }

  badge(catId) {
    const c = Category.create({ id: catId });
    return categoryBadgeHTML(c, { allowUncategorized: true });
  }

  <template>
    <div class="related-expandable-item">
      <div class="related-category-btns">
        <DButton
          @action={{this.toggleContent}}
          @icon={{if this.isOpen "chevron-up" "chevron-right"}}
          @translatedLabel={{this.combinedLabel}}
          class="btn btn-transparent expand-category-btn"
        />

        <DButton
          @icon="arrow-right"
          @translatedLabel={{i18n (themePrefix "settings")}}
          @href={{concat "/c/" @slugPath "/edit/security"}}
          class="btn btn-transparent goto-settings-btn"
        />
      </div>
      {{#if this.isOpen}}
        {{#if this.isLoading}}
          <p>{{i18n (themePrefix "loading")}}</p>
        {{else}}
          <div class="category-permissions-table">
            <div class="permission-row row-header">
              <span class="group-name">{{i18n
                  "category.permissions.group"
                }}</span>
              <span class="options">
                <span class="cell">{{i18n "category.permissions.see"}}</span>
                <span class="cell">{{i18n "category.permissions.reply"}}</span>
                <span class="cell">{{i18n "category.permissions.create"}}</span>
                <span class="cell"></span>
              </span>
            </div>

            {{#each this.loadedContent.group_permissions as |cp|}}
              <div
                class="permission-row row-body"
                data-group-name={{cp.group_name}}
              >
                <span class="group-name">
                  <span class="group-name-label">{{cp.group_name}}</span>
                </span>
                <span class="options actionable">
                  <span class="cell">{{icon "square-check"}}</span>
                  {{#if
                    (or (eq cp.permission_type 1) (eq cp.permission_type 2))
                  }}
                    <span class="cell">{{icon "square-check"}}</span>
                  {{else}}
                    <span class="cell">{{icon "far-square"}}</span>
                  {{/if}}
                  {{#if (eq cp.permission_type 1)}}
                    <span class="cell">{{icon "square-check"}}</span>
                  {{else}}
                    <span class="cell">{{icon "far-square"}}</span>
                  {{/if}}
                  <span class="cell"></span>
                </span>
              </div>
            {{/each}}
          </div>
          {{#if @checkSubSub}}
            {{#if this.subcategories}}
              <div class="related-sub-subcategories">
                <h4>{{i18n (themePrefix "sub_subcategories")}}</h4>
                <div class="related-sub-subcategory-list">
                  {{#each this.subcategories as |subcategory|}}
                    <ExpandableItemComponent
                      @label={{subcategory.name}}
                      @slugPath={{this.getSlugPath subcategory}}
                      @catID={{subcategory.id}}
                    />
                  {{/each}}
                </div>
              </div>
            {{/if}}
          {{/if}}
        {{/if}}
      {{/if}}
    </div>
  </template>
}
