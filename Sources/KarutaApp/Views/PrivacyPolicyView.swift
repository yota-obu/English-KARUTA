import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(FontStyles.titleMedium)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("Last updated: April 10, 2026")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)

                    section(
                        title: "1. はじめに",
                        body: "本アプリ「英単語かるた」（以下「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本ポリシーは、本アプリにおける情報の取り扱いについて説明します。"
                    )

                    section(
                        title: "2. 収集する情報",
                        body: "本アプリは、ユーザーの個人情報（氏名、メールアドレス、電話番号など）を収集しません。ゲームのスコア、プレイ履歴、復習データなどはすべてユーザーの端末内にのみ保存され、外部のサーバーに送信されることはありません。"
                    )

                    section(
                        title: "3. データの利用",
                        body: "端末内に保存されるデータは、アプリの機能（プレイ履歴の表示、復習機能など）を提供するためにのみ使用されます。"
                    )

                    section(
                        title: "4. データの第三者提供",
                        body: "本アプリは、ユーザーのデータを第三者に提供、販売、共有することはありません。"
                    )

                    section(
                        title: "5. データの削除",
                        body: "ユーザーは設定画面の「Clear All History」からいつでも保存されているすべてのデータを削除できます。また、本アプリをアンインストールすることで、端末内のすべてのデータが削除されます。"
                    )

                    section(
                        title: "6. 子どものプライバシー",
                        body: "本アプリはあらゆる年齢のユーザーが安全にご利用いただけるよう設計されており、年齢を問わず個人情報を収集することはありません。"
                    )

                    section(
                        title: "7. 本ポリシーの変更",
                        body: "本プライバシーポリシーは、必要に応じて更新されることがあります。重要な変更があった場合は、本アプリのアップデートを通じてお知らせします。"
                    )

                    section(
                        title: "8. お問い合わせ",
                        body: "本プライバシーポリシーに関するご質問やご意見がございましたら、設定画面の「Send Feedback」よりお問い合わせください。"
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(FontStyles.titleSmall)
                .foregroundStyle(ColorPalette.textPrimary)
            Text(body)
                .font(FontStyles.bodyMedium)
                .foregroundStyle(ColorPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
