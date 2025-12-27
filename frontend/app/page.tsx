'use client'

export default function Home() {
    return (
    <div className="min-h-screen bg-white">
      {/* Hero Section with Image */}
      <section className="relative h-screen flex items-center justify-center overflow-hidden">
        {/* Background Image */}
        <div className="absolute inset-0 z-0">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-900/90 to-purple-900/90 z-10"></div>
          <div className="w-full h-full bg-gradient-to-br from-blue-600 via-purple-600 to-indigo-800 opacity-80"></div>
          {/* Abstract tech pattern overlay */}
          <div className="absolute inset-0 opacity-20">
            <div className="absolute top-20 left-20 w-72 h-72 bg-blue-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse"></div>
            <div className="absolute top-40 right-20 w-72 h-72 bg-purple-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse delay-700"></div>
            <div className="absolute bottom-20 left-1/2 w-72 h-72 bg-indigo-400 rounded-full mix-blend-multiply filter blur-xl animate-pulse delay-1000"></div>
          </div>
        </div>

        {/* Content */}
        <div className="relative z-20 text-center px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto">
          <h1 className="text-5xl md:text-7xl font-bold text-white mb-6 animate-fade-in">
            ТОВ Лекс ЕйАй
          </h1>
          <p className="text-2xl md:text-4xl text-blue-100 mb-4 font-light">
            Lex AI
          </p>
          <p className="text-xl md:text-2xl text-white/90 mb-8 max-w-3xl mx-auto">
            Ваш персональний юридичний помічник
          </p>
          <p className="text-lg md:text-xl text-blue-100 mb-12 max-w-2xl mx-auto">
            IT розробка та технічне супроводження проектів
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <a 
              href="#services" 
              className="bg-white text-blue-900 px-8 py-4 rounded-lg font-semibold text-lg hover:bg-blue-50 transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-1"
            >
              Наші послуги
            </a>
            <a 
              href="#contact" 
              className="bg-transparent border-2 border-white text-white px-8 py-4 rounded-lg font-semibold text-lg hover:bg-white/10 transition-all"
          >
              Зв'язатися з нами
            </a>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-10 left-1/2 transform -translate-x-1/2 z-20 animate-bounce">
          <svg className="w-6 h-6 text-white" fill="none" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" viewBox="0 0 24 24" stroke="currentColor">
            <path d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
          </svg>
      </div>
      </section>

      {/* About Section */}
      <section id="about" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Про компанію</h2>
            <div className="w-24 h-1 bg-blue-600 mx-auto"></div>
          </div>
          
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div>
              <h3 className="text-2xl font-semibold text-gray-900 mb-4">
                ТОВ Лекс ЕйАй (Lex AI) 2025
              </h3>
              <p className="text-lg text-gray-700 mb-4">
                Ми - українська IT компанія, що спеціалізується на розробці програмного забезпечення 
                та технічному супроводі проектів у сфері інформаційних технологій.
              </p>
              <p className="text-lg text-gray-700 mb-4">
                Наша команда має багаторічний досвід у створенні інноваційних рішень та інтеграції 
                складних систем для юридичного та державного сектору.
              </p>
              <p className="text-lg text-gray-700">
                Ми працюємо з сучасними технологіями та надаємо повний цикл послуг від аналізу 
                вимог до підтримки готових рішень.
              </p>
            </div>
            
            <div className="bg-white p-8 rounded-lg shadow-lg">
              <div className="grid grid-cols-2 gap-6">
                <div className="text-center">
                  <div className="text-4xl font-bold text-blue-600 mb-2">2025</div>
                  <div className="text-gray-600">Рік заснування</div>
                </div>
                <div className="text-center">
                  <div className="text-4xl font-bold text-blue-600 mb-2">100%</div>
                  <div className="text-gray-600">Українська компанія</div>
                </div>
                <div className="text-center">
                  <div className="text-4xl font-bold text-blue-600 mb-2">24/7</div>
                  <div className="text-gray-600">Техпідтримка</div>
                </div>
                <div className="text-center">
                  <div className="text-4xl font-bold text-blue-600 mb-2">∞</div>
                  <div className="text-gray-600">Досвід інтеграцій</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section id="services" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Наші послуги</h2>
            <div className="w-24 h-1 bg-blue-600 mx-auto mb-4"></div>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Комплексні IT рішення для вашого бізнесу
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Service 1 */}
            <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-8 rounded-lg shadow-lg hover:shadow-xl transition-all transform hover:-translate-y-2">
              <div className="w-16 h-16 bg-blue-600 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
                </svg>
              </div>
              <h3 className="text-2xl font-semibold text-gray-900 mb-4">IT Розробка</h3>
              <p className="text-gray-700">
                Розробка програмного забезпечення під ваші потреби. 
                Створення веб-додатків, мобільних застосунків та корпоративних систем.
              </p>
            </div>

            {/* Service 2 */}
            <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-8 rounded-lg shadow-lg hover:shadow-xl transition-all transform hover:-translate-y-2">
              <div className="w-16 h-16 bg-purple-600 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <h3 className="text-2xl font-semibold text-gray-900 mb-4">Технічне супроводження</h3>
              <p className="text-gray-700">
                Повний технічний супровід IT проектів. Моніторинг, оновлення, 
                виправлення помилок та оптимізація роботи систем.
              </p>
            </div>

            {/* Service 3 */}
            <div className="bg-gradient-to-br from-indigo-50 to-blue-50 p-8 rounded-lg shadow-lg hover:shadow-xl transition-all transform hover:-translate-y-2">
              <div className="w-16 h-16 bg-indigo-600 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                </svg>
              </div>
              <h3 className="text-2xl font-semibold text-gray-900 mb-4">Інтеграції</h3>
              <p className="text-gray-700">
                Інтеграція з державними та комерційними сервісами. 
                Досвід роботи з Закононлайн, Укрпатент, Рада.гов.юа та іншими системами.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Integration Experience Section */}
      <section className="py-20 bg-gradient-to-br from-blue-600 to-indigo-700 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Досвід інтеграцій</h2>
            <div className="w-24 h-1 bg-white mx-auto mb-4"></div>
            <p className="text-xl text-blue-100 max-w-2xl mx-auto">
              Ми маємо успішний досвід інтеграції з провідними українськими сервісами
            </p>
                          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white/10 backdrop-blur-lg p-8 rounded-lg border border-white/20">
              <div className="text-4xl mb-4">⚖️</div>
              <h3 className="text-2xl font-semibold mb-4">Закононлайн</h3>
              <p className="text-blue-100">
                Інтеграція з базою даних судових рішень та нормативно-правових актів
              </p>
                        </div>

            <div className="bg-white/10 backdrop-blur-lg p-8 rounded-lg border border-white/20">
              <div className="text-4xl mb-4">📜</div>
              <h3 className="text-2xl font-semibold mb-4">Укрпатент</h3>
              <p className="text-blue-100">
                Робота з системою інтелектуальної власності та патентів
              </p>
                          </div>

            <div className="bg-white/10 backdrop-blur-lg p-8 rounded-lg border border-white/20">
              <div className="text-4xl mb-4">🏛️</div>
              <h3 className="text-2xl font-semibold mb-4">Рада.гов.юа</h3>
              <p className="text-blue-100">
                Інтеграція з державними системами та електронним документообігом
              </p>
                        </div>
                      </div>

          <div className="mt-12 text-center">
            <p className="text-xl text-blue-100">
              Та багато інших державних та комерційних сервісів
            </p>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="contact" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Зв'яжіться з нами</h2>
            <div className="w-24 h-1 bg-blue-600 mx-auto mb-4"></div>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Готові обговорити ваш проект та запропонувати найкраще рішення
            </p>
          </div>
          
          <div className="max-w-3xl mx-auto">
            <div className="bg-white rounded-lg shadow-xl p-8 md:p-12">
              <div className="grid md:grid-cols-2 gap-8">
                {/* Phone */}
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Телефон</h3>
                    <a 
                      href="tel:+380677206353" 
                      className="text-blue-600 hover:text-blue-800 text-xl font-medium"
                    >
                      +380 67 720 63 53
                    </a>
                  </div>
          </div>
          
                {/* Email */}
                <div className="flex items-start space-x-4">
                  <div className="w-12 h-12 bg-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-2">Email</h3>
                    <a 
                      href="mailto:igor_kirichenko@urk.net" 
                      className="text-purple-600 hover:text-purple-800 text-xl font-medium break-all"
                    >
                      igor_kirichenko@urk.net
                    </a>
                  </div>
                </div>
          </div>
          
              <div className="mt-8 pt-8 border-t border-gray-200">
                <div className="text-center">
                  <p className="text-gray-600 mb-4">ТОВ Лекс ЕйАй (Lex AI)</p>
                  <p className="text-gray-500">© 2025 Всі права захищені</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p className="text-gray-400">
            ТОВ Лекс ЕйАй - Ваш надійний партнер у сфері IT розробки та технічного супроводу
          </p>
        </div>
      </footer>
    </div>
  )
}
