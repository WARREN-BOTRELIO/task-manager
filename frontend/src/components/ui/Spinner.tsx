import { cn } from '@/utils/cn'

export function Spinner({ size = 'md', light = false }: { size?: 'sm' | 'md'; light?: boolean }) {
  const sizeClass = size === 'sm' ? 'h-4 w-4' : 'h-6 w-6'
  return (
    <svg
      className={cn('animate-spin', sizeClass, light ? 'text-white' : 'text-slate-500')}
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
    </svg>
  )
}