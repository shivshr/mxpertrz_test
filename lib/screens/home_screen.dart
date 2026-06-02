part of '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        body: SafeArea(
          child: StreamBuilder<HomeContent>(
            stream: HomeRepository().watchHome(),
            initialData: HomeContent.sample(),
            builder: (context, snapshot) {
              final content = snapshot.data ?? HomeContent.sample();
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _HomeHeader(content: content)),
                  SliverToBoxAdapter(child: _CategoryTabs(content.categories)),
                  SliverToBoxAdapter(child: _ShortcutGrid(content.categories)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                    sliver: SliverGrid.builder(
                      itemCount: content.products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: .64,
                          ),
                      itemBuilder: (context, index) =>
                          ProductCard(content.products[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: const _BottomNav(),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.content});

  final HomeContent content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu, size: 24),
              Spacer(),
              BrandLogo(size: 68),
              Spacer(),
              Icon(Icons.search, size: 27),
              SizedBox(width: 14),
              Icon(Icons.fit_screen, size: 23),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            content.greeting,
            style: const TextStyle(fontSize: 15, color: _ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'What are you looking for\ntoday?',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          PromoBanner(content.bannerTitle, content.bannerSubtitle),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '••••',
              style: TextStyle(color: _orange, fontSize: 22, letterSpacing: 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs(this.categories);

  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    final names = [
      'Recommend',
      'Cell Phone',
      'Car Products',
      'Department Store',
    ];
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (_, _) => const SizedBox(width: 22),
        itemBuilder: (context, index) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              index < categories.length ? categories[index].name : names[index],
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 40,
              height: 2,
              child: ColoredBox(
                color: index == 1 ? _orange : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid(this.categories);

  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'See More',
            style: TextStyle(
              color: _orange,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: .84,
            ),
            itemBuilder: (context, index) => ShortcutTile(categories[index]),
          ),
        ],
      ),
    );
  }
}
