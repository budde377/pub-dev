// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../package/models.dart';
import '../../../../search/search_service.dart';
import '../../../../shared/tags.dart';
import '../../../../shared/urls.dart' as urls;
import '../../../../shared/utils.dart' show shortDateFormat;

import '../../../dom/dom.dart' as d;
import '../../../static_files.dart' show staticUrls;
import '../../_consts.dart';
import '../../package_misc.dart';

/// Renders the listing page (list of packages).
d.Node listOfPackagesNode({
  required PackageView? highlightedHit,
  required List<SdkLibraryHit> sdkLibraryHits,
  required List<PackageView> packageHits,
}) {
  return d.div(
    classes: ['packages'],
    children: [
      if (highlightedHit != null) _packageItem(highlightedHit),
      ...sdkLibraryHits.map(_sdkLibraryItem),
      ...packageHits.map(_packageItem),
    ],
  );
}

d.Node _sdkLibraryItem(SdkLibraryHit hit) {
  final sdkDict = getSdkDict(hit.sdk!);
  final metadataText = [
    if (hit.version != null) 'v ${hit.version}',
    sdkDict.libraryTypeLabel,
  ].join(' • ');

  return _item(
    url: hit.url!,
    name: hit.library!,
    newTimestamp: null,
    labeledScoresNode: null,
    description: hit.description ?? '',
    metadataNode: d.text(metadataText),
    tagsNode: null,
    apiPages: null,
  );
}

d.Node _packageItem(PackageView view) {
  final isFlutterFavorite = view.tags.contains(PackageTags.isFlutterFavorite);
  final isNullSafe = view.tags.contains(PackageVersionTags.isNullSafe);

  final metadataNode = d.fragment([
    d.span(
      classes: ['packages-metadata-block'],
      children: [
        d.text('v '),
        d.a(href: urls.pkgPageUrl(view.name!), text: view.version),
        if (view.previewVersion != null) ...[
          d.text(' / '),
          d.a(
            href: urls.pkgPageUrl(view.name!, version: view.previewVersion),
            text: view.previewVersion,
          ),
        ],
        if (view.prereleaseVersion != null) ...[
          d.text('/ '),
          d.a(
            href: urls.pkgPageUrl(view.name!, version: view.prereleaseVersion),
            text: view.prereleaseVersion,
          ),
        ],
        d.text(' • Updated: '),
        d.span(
          text: view.updated == null
              ? null
              : shortDateFormat.format(view.updated!),
        ),
      ],
    ),
    if (view.publisherId != null)
      d.span(classes: [
        'packages-metadata-block'
      ], children: [
        d.img(
          classes: ['package-vp-icon'],
          src:
              staticUrls.getAssetUrl('/static/img/verified-publisher-icon.svg'),
          title: 'Published by a pub.dev verified publisher',
        ),
        d.a(href: urls.publisherUrl(view.publisherId!), text: view.publisherId),
      ]),
    if (isFlutterFavorite) flutterFavoriteBadgeNode,
    if (isNullSafe) nullSafeBadgeNode(),
  ]);

  return _item(
    url: urls.pkgPageUrl(view.name!),
    name: view.name!,
    newTimestamp: view.created,
    labeledScoresNode: labeledScoresNodeFromPackageView(view),
    description: view.ellipsizedDescription ?? '',
    metadataNode: metadataNode,
    tagsNode: tagsNodeFromPackageView(package: view),
    apiPages: view.apiPages
        ?.map((page) => _ApiPageUrl(
              page.url ??
                  urls.pkgDocUrl(
                    view.name!,
                    isLatest: true,
                    relativePath: page.path,
                  ),
              page.title ?? page.path!,
            ))
        .toList(),
  );
}

d.Node _item({
  required String url,
  required String name,
  required DateTime? newTimestamp,
  required d.Node? labeledScoresNode,
  required String description,
  required d.Node metadataNode,
  required d.Node? tagsNode,
  required List<_ApiPageUrl>? apiPages,
}) {
  final xAgoLabel = _renderXAgo(newTimestamp);
  return d.div(
    classes: ['packages-item'],
    children: [
      d.div(
        classes: ['packages-header'],
        children: [
          d.h3(
            classes: ['packages-title'],
            child: d.a(href: url, text: name),
          ),
          if (xAgoLabel != null)
            d.div(
              classes: ['packages-recent'],
              children: [
                d.img(
                  classes: ['packages-recent-icon'],
                  src: staticUrls.getAssetUrl('/static/img/schedule-icon.svg'),
                  title: 'new package',
                ),
                d.text(' Added '),
                d.b(text: xAgoLabel),
              ],
            ),
          if (labeledScoresNode != null) labeledScoresNode,
        ],
      ), // end of packages-header

      d.p(classes: ['packages-description'], text: description),
      d.p(classes: ['packages-metadata'], child: metadataNode),
      if (tagsNode != null) d.div(child: tagsNode),
      if (apiPages != null && apiPages.isNotEmpty)
        d.div(classes: ['packages-api'], child: _apiPages(apiPages)),
    ],
  );
}

String? _renderXAgo(DateTime? value) {
  if (value == null) return null;
  final age = DateTime.now().difference(value);
  if (age.inDays > 30) return null;
  if (age.inDays > 1) return '${age.inDays} days ago';
  if (age.inHours > 1) return '${age.inHours} hours ago';
  return 'in the last hour';
}

class _ApiPageUrl {
  final String href;
  final String label;

  _ApiPageUrl(this.href, this.label);
}

d.Node _apiPages(List<_ApiPageUrl> apiPages) {
  if (apiPages.length == 1) {
    return d.fragment([
      d.div(classes: ['packages-api-label'], text: 'API result:'),
      d.div(
        classes: ['packages-api-links'],
        child: d.a(
          href: apiPages.single.href,
          text: apiPages.single.label,
        ),
      ),
    ]);
  } else {
    return d.fragment([
      d.div(classes: ['packages-api-label'], text: 'API results:'),
      d.details(
        classes: ['packages-api-details', 'packages-api-links'],
        summary: [d.a(href: apiPages.first.href, text: apiPages.first.label)],
        children: apiPages.skip(1).map(
              (e) => d.div(
                classes: ['-rest'],
                child: d.a(href: e.href, text: e.label),
              ),
            ),
      ),
    ]);
  }
}