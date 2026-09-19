import { forwardRef, useId, type TextareaHTMLAttributes } from 'react'
import { cn } from '@/utils/cn'

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label: string
  error?: string
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  function Textarea({ label, error, className, id, ...props }, ref) {
    const autoId = useId()
    const textareaId = id ?? autoId

    return (
      <div className="space-y-1">
        <label htmlFor={textareaId} className="block text-sm font-medium text-slate-700">
          {label}
        </label>
        <textarea
          ref={ref}
          id={textareaId}
          rows={3}
          className={cn(
            'w-full resize-none rounded-lg border bg-white px-3 py-2.5 text-sm text-slate-900 placeholder:text-slate-400',
            'focus:outline-2 focus:outline-offset-1',
            error
              ? 'border-red-400 focus:outline-red-500'
              : 'border-slate-300 focus:outline-slate-500',
            className,
          )}
          {...props}
        />
        {error ? <p className="text-xs text-red-600">{error}</p> : null}
      </div>
    )
  },
)