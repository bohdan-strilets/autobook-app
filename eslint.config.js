import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import react from 'eslint-plugin-react'
import reactHooks from 'eslint-plugin-react-hooks'
import importPlugin from 'eslint-plugin-import'
import eslintConfigPrettier from 'eslint-config-prettier/flat'
import globals from 'globals'

export default [
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/.expo/**',
      '**/.turbo/**',
      '**/coverage/**',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommended,

  {
    files: ['**/*.{ts,tsx}'],

    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {},
    },

    plugins: {
      react,
      'react-hooks': reactHooks,
      import: importPlugin,
    },

    rules: {
      'react/react-in-jsx-scope': 'off',

      ...reactHooks.configs.recommended.rules,

      '@typescript-eslint/no-unused-vars': 'warn',

      'import/order': 'off',

      'no-console': 'warn',
    },

    settings: {
      react: {
        version: 'detect',
      },
    },
  },

  {
    files: [
      '**/*.config.js',
      '**/*.config.cjs',
      '**/metro.config.js',
      '**/metro.config.cjs',
    ],

    languageOptions: {
      sourceType: 'commonjs',
      globals: { ...globals.node },
    },

    rules: {
      '@typescript-eslint/no-require-imports': 'off',
    },
  },

  eslintConfigPrettier,
]
